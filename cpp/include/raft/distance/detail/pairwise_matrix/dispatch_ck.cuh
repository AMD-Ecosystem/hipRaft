/*
 * Copyright (c) 2024-2025, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#pragma once

// Composable Kernel (CK) MFMA backing for raft's expanded pairwise distances on
// AMD gfx90a. This is the ROCm replacement for the CUTLASS SM80 path
// (pairwise_distance_cutlass_base.cuh + dispatch_sm80.cuh), which does not port
// to ROCm. It is HIP-only and used solely by
// pairwise_matrix_dispatch when the regime is CK-eligible; arbitrary shapes fall
// back to raft's SIMT/sm60 path, mirroring raft's CUDA alignment dispatch.
//
// The CUTLASS distance kernel is a GemmUniversal whose epilogue applies the
// distance op: the GEMM computes accVal = dot(x_i, y_j) and the epilogue emits
// out[i][j] = fin_op(distance_op(xn[i], yn[j], accVal)). Here the identical
// intent is expressed with CK's DeviceGemmMultipleD_Xdl_CShuffle: the XDL/MFMA
// GEMM computes C = X * Y^T and a fused CDE element op consumes the accumulator
// plus the two norm tensors (d0 = ||x_m||^2 row-broadcast, d1 = ||y_n||^2
// col-broadcast). CK only supports Row-major D and a stride-0 Row D broadcasts
// the N-vector (yn); the per-M norm (xn) is therefore materialized [M, N].
#if defined(__HIP_PLATFORM_AMD__)

#include <raft/core/error.hpp>                              // RAFT_CUDA_TRY
#include <raft/distance/detail/distance_ops/cosine.cuh>     // ops::cosine_distance_op
#include <raft/distance/detail/distance_ops/l2_exp.cuh>     // ops::l2_exp_distance_op
#include <raft/distance/detail/pairwise_matrix/params.cuh>  // pairwise_matrix_params

#include <rmm/device_uvector.hpp>

#include <hip/hip_runtime.h>

#include <ck/ck.hpp>
#include <ck/host_utility/device_prop.hpp>
#include <ck/stream_config.hpp>
#include <ck/tensor_operation/gpu/device/gemm_specialization.hpp>
#include <ck/tensor_operation/gpu/device/impl/device_gemm_multiple_d_xdl_cshuffle.hpp>
#include <ck/tensor_operation/gpu/device/tensor_layout.hpp>
#include <ck/tensor_operation/gpu/element/element_wise_operation.hpp>

#include <array>
#include <cstdint>
#include <type_traits>

namespace raft::distance::detail {

// Which distance ops have a CK MFMA implementation. Both have a CUTLASS twin
// upstream; on ROCm we provide the CK equivalent of that twin. Anything else
// (and any unsupported DataT/OutT) takes the SIMT fallback.
template <typename OpT>
struct is_ck_distance_op : std::false_type {};
template <typename D, typename A, typename I>
struct is_ck_distance_op<ops::l2_exp_distance_op<D, A, I>> : std::true_type {};
template <typename D, typename A, typename I>
struct is_ck_distance_op<ops::cosine_distance_op<D, A, I>> : std::true_type {};

namespace ck_detail {

using Row         = ck::tensor_layout::gemm::RowMajor;
using Col         = ck::tensor_layout::gemm::ColumnMajor;
using PassThrough = ck::tensor_operation::element_wise::PassThrough;

// CDE element op: E = fin_op( distance(d0, d1, c) ), with d0 = ||x_m||^2 (row),
// d1 = ||y_n||^2 (col), c = <x_m, y_n>. The two formulas below are byte-for-byte
// the same arithmetic as ops::l2_exp_cutlass_op / ops::cosine_cutlass_op (incl.
// the L2 self-neighbor round-off clamp), so the CK output matches raft's SIMT
// reference numerically. distance_kind: 0 = expanded L2, 1 = cosine.
template <typename DataT, typename FinOpT, int distance_kind>
struct DistanceCDEOp {
  FinOpT fin_op;
  bool do_sqrt;

  template <typename DataTT>
  __host__ __device__ static constexpr DataTT clamp_precision()
  {
    switch (sizeof(DataTT)) {
      case 2: return DataTT(1e-3);
      case 4: return DataTT(1e-6);
      case 8: return DataTT(1e-15);
      default: return DataTT(0);
    }
  }

  template <typename E, typename C, typename D0, typename D1>
  __host__ __device__ void operator()(E& e, const C& c, const D0& d0, const D1& d1) const
  {
    DataT aNorm  = ck::type_convert<DataT>(d0);
    DataT bNorm  = ck::type_convert<DataT>(d1);
    DataT accVal = ck::type_convert<DataT>(c);

    DataT outVal;
    if constexpr (distance_kind == 0) {
      outVal = aNorm + bNorm - DataT(2.0) * accVal;
      outVal = outVal * !((outVal * outVal < clamp_precision<DataT>()) * (aNorm == bNorm));
      if (do_sqrt) { outVal = ::sqrtf(outVal * (outVal > DataT(0))); }
    } else {
      outVal = DataT(1.0) - (accVal / (aNorm * bNorm));
    }
    e = ck::type_convert<E>(fin_op(outVal, 0));
  }
};

// Materialize the per-M norm into d0[M, N] (Row, stride N): d0[m, n] = xn[m].
template <typename DataT, typename IdxT>
__global__ void broadcast_row_norm_kernel(DataT* d0, const DataT* xn, IdxT m, IdxT n)
{
  const std::size_t total = static_cast<std::size_t>(m) * static_cast<std::size_t>(n);
  for (std::size_t idx = static_cast<std::size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
       idx < total;
       idx += static_cast<std::size_t>(gridDim.x) * blockDim.x) {
    d0[idx] = xn[idx / static_cast<std::size_t>(n)];
  }
}

// fp32 XDL instance: 16x16x16 MFMA on gfx90a (v_mfma_f32_16x16x16f32). Vector
// width 4 on the CDE/A/B loads requires N%4==0 and K%4==0; MNKPadding pads M.
template <int distance_kind, typename FinOpT>
using DeviceL2 = ck::tensor_operation::device::DeviceGemmMultipleD_Xdl_CShuffle<
  Row,                       // A: X[M,K] row-major
  Col,                       // B: Y[N,K] row-major == B[K,N] col-major
  ck::Tuple<Row, Row>,       // Ds: d0 [M,N] (stride N), d1 [N] (stride 0)
  Row,                       // E: D[M,N] row-major
  float,
  float,
  float,                     // AccDataType
  float,                     // CShuffleDataType
  ck::Tuple<float, float>,   // DsDataType
  float,                     // EDataType
  PassThrough,
  PassThrough,
  DistanceCDEOp<float, FinOpT, distance_kind>,
  ck::tensor_operation::device::GemmSpecialization::MNKPadding,
  1, 256, 256, 128, 32, 4, 4, 32, 32, 4, 2,
  ck::Sequence<4, 64, 1>, ck::Sequence<1, 0, 2>, ck::Sequence<1, 0, 2>, 2, 4, 4, 1,
  ck::Sequence<4, 64, 1>, ck::Sequence<1, 0, 2>, ck::Sequence<1, 0, 2>, 2, 4, 4, 1,
  1, 1, ck::Sequence<1, 32, 1, 8>, 4>;

}  // namespace ck_detail

// Runtime gate: the tuned CK instance is fp32, row-major, and needs N%4==0 /
// K%4==0 (the vector loads). Also gated on CK arch support: the tuned instance
// uses MPerXDL=32/NPerXDL=32 (gfx90a MFMA), which CK does not support on gfx11
// (RDNA3, wave32 -- WMMA not MFMA). On gfx1100 this check returns false and the
// SIMT fallback handles all distances correctly. params is already flipped for
// column-major, so params.x/x_norm is [m,k]/per-m here.
template <typename OpT, typename IdxT, typename DataT, typename OutT, typename FinOpT>
bool pairwise_matrix_ck_can_dispatch(
  pairwise_matrix_params<IdxT, DataT, OutT, FinOpT> params)
{
  if (!is_ck_distance_op<OpT>::value) { return false; }
  if (!(std::is_same_v<DataT, float> && std::is_same_v<OutT, float>)) { return false; }
  if (!params.is_row_major) { return false; }
  if (params.x_norm == nullptr || params.y_norm == nullptr) { return false; }
  if (params.m <= 0 || params.n <= 0 || params.k <= 0) { return false; }
  if ((params.n % 4 != 0) || (params.k % 4 != 0)) { return false; }
  // DeviceL2 uses MPerXDL=32, NPerXDL=32: only supported on gfx90a/CDNA.
  if (!ck::is_xdl_wmma_supported<float, float, 32, 32>()) { return false; }
  return true;
}

template <typename OpT, typename IdxT, typename DataT, typename OutT, typename FinOpT>
void pairwise_matrix_ck_dispatch(OpT distance_op,
                                 pairwise_matrix_params<IdxT, DataT, OutT, FinOpT> params,
                                 cudaStream_t stream)
{
  static_assert(std::is_same_v<DataT, float> && std::is_same_v<OutT, float>,
                "CK distance path is fp32 only");

  constexpr int kind = std::is_same_v<OpT, ops::cosine_distance_op<DataT, typename OpT::AccT, IdxT>>
                         ? 1
                         : 0;
  // L2 carries a sqrt flag (L2Expanded vs L2SqrtExpanded); cosine has none.
  bool sqrt_flag = false;
  if constexpr (kind == 0) { sqrt_flag = static_cast<bool>(distance_op.sqrt); }

  const int M = static_cast<int>(params.m);
  const int N = static_cast<int>(params.n);
  const int K = static_cast<int>(params.k);

  const int StrideA = static_cast<int>(params.ldx);     // X[M,K] row-major, ld = k
  const int StrideB = static_cast<int>(params.ldy);     // Y[N,K] row-major, ld = k
  const int StrideE = static_cast<int>(params.ld_out);  // D[M,N] row-major, ld = n

  rmm::device_uvector<float> d0(static_cast<std::size_t>(M) * static_cast<std::size_t>(N), stream);
  {
    const std::size_t total = static_cast<std::size_t>(M) * static_cast<std::size_t>(N);
    const int block         = 256;
    const std::size_t grid_sz =
      std::min<std::size_t>((total + block - 1) / block, static_cast<std::size_t>(65535));
    ck_detail::broadcast_row_norm_kernel<float, IdxT>
      <<<static_cast<unsigned>(grid_sz), block, 0, stream>>>(
        d0.data(), params.x_norm, static_cast<IdxT>(M), static_cast<IdxT>(N));
    RAFT_CUDA_TRY(cudaPeekAtLastError());
  }

  using DeviceOp     = ck_detail::DeviceL2<kind, FinOpT>;
  using CDEOp        = ck_detail::DistanceCDEOp<float, FinOpT, kind>;
  auto device_op     = DeviceOp{};
  auto invoker       = device_op.MakeInvoker();
  auto cde_op        = CDEOp{params.fin_op, sqrt_flag};
  auto argument      = device_op.MakeArgument(
    params.x,
    params.y,
    std::array<const void*, 2>{d0.data(), params.y_norm},
    params.out,
    M, N, K,
    StrideA, StrideB,
    std::array<ck::index_t, 2>{N, 0},  // d0 full [M,N] (stride N); d1 broadcast (stride 0)
    StrideE,
    ck_detail::PassThrough{}, ck_detail::PassThrough{}, cde_op);

  RAFT_EXPECTS(device_op.IsSupportedArgument(argument),
               "raft CK distance: arguments not supported by the CK instance");

  invoker.Run(argument, StreamConfig{stream, false});
}

}  // namespace raft::distance::detail

#endif  // defined(__HIP_PLATFORM_AMD__)

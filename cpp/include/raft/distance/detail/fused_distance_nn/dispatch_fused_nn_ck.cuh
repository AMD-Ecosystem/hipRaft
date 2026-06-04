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

// Composable Kernel (CK) MFMA backing for raft's fused distance + 1-NN
// (fusedL2NN / fusedCosineNN) on AMD gfx90a. This is the ROCm replacement for
// the CUTLASS fused-distance-NN path (fused_distance_nn/cutlass_base.cuh +
// the reducing epilogue in predicated_tile_iterator_reduced_vec.h), which does
// not port to ROCm. HIP-only; fusedL2NNImpl routes
// here when the regime is CK-eligible and to raft's SIMT kernel otherwise,
// mirroring raft's CUDA alignment dispatch.
//
// The CUTLASS fused-NN kernel is a GemmUniversal whose epilogue, instead of
// writing the [M,N] distance matrix, reduces each row to a KeyValuePair{argmin
// column, min distance}. CK's reduce family (DeviceGemmReduce) reduces scalar
// values and does not carry the argmin column, so the index would be lost. We
// therefore express the identical intent as TWO fused steps that reuse the
// CK distance GEMM (dispatch_ck.cuh):
//   1. the XDL/MFMA DeviceGemmMultipleD_Xdl_CShuffle computes the row-major
//      distance matrix D[m,n] = fin_op(distance_op(xn[m], yn[n], <x_m,y_n>)),
//      byte-identical to the SIMT distance values that feed the SIMT argmin;
//   2. a per-row argmin reduction kernel reduces D[m,:] to the KeyValuePair and
//      applies raft's ReduceOpT into the output, plus the per-row mutex update.
// Step 2 is a plain block-per-row shared-memory reduction (no warp shuffles), so
// it is wave64-correct by construction. The argmin is numerically exact: the
// only fp32 error is in the GEMM dot product, the same error the standalone CK
// distance path already validates against a double-precision reference.
#if defined(__HIP_PLATFORM_AMD__)

#include <raft/core/error.hpp>                           // RAFT_CUDA_TRY, RAFT_EXPECTS
#include <raft/core/kvp.hpp>                              // raft::KeyValuePair
#include <raft/core/operators.hpp>                        // raft::identity_op
#include <raft/distance/detail/distance_ops/l2_exp.cuh>   // ops::get_clamp_precision
#include <raft/distance/distance_types.hpp>               // raft::distance::DistanceType

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
#include <limits>
#include <type_traits>

namespace raft::distance::detail {

namespace ck_fused_nn {

using Row         = ck::tensor_layout::gemm::RowMajor;
using Col         = ck::tensor_layout::gemm::ColumnMajor;
using PassThrough = ck::tensor_operation::element_wise::PassThrough;

// CDE element op writing the [M,N] distance matrix. distance_kind 0 = expanded
// L2 (with the L2SqrtExpanded sqrt flag), 1 = cosine. This reproduces
// ops::l2_exp_distance_op::epilog (NOT l2_exp_cutlass_op) byte-for-byte, since
// fusedL2NNImpl constructs l2_exp_distance_op{sqrt} as the distance op whose
// values are argmin'd: the non-sqrt path applies the (val>0) relu and the
// self-neighbor round-off clamp, and the sqrt path takes sqrt of that. fin_op
// is identity for fused-NN (matches fused_l2_nn.cuh) but is applied here so any
// future fin_op stays consistent with the SIMT store_output.
template <typename DataT, typename FinOpT, int distance_kind>
struct DistanceFusedCDEOp {
  FinOpT fin_op;
  bool do_sqrt;

  template <typename E, typename C, typename D0, typename D1>
  __host__ __device__ void operator()(E& e, const C& c, const D0& d0, const D1& d1) const
  {
    DataT aNorm  = ck::type_convert<DataT>(d0);
    DataT bNorm  = ck::type_convert<DataT>(d1);
    DataT accVal = ck::type_convert<DataT>(c);

    DataT outVal;
    if constexpr (distance_kind == 0) {
      DataT val = aNorm + bNorm - DataT(2.0) * accVal;
      val       = val * (val > DataT(0)) *
            !((val * val < ops::get_clamp_precision<DataT>()) * (aNorm == bNorm));
      outVal = do_sqrt ? ::sqrtf(val) : val;
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
// Identical tuning to dispatch_ck.cuh's DeviceL2 (the validated distance GEMM).
template <int distance_kind, typename FinOpT>
using DeviceFusedNNGemm = ck::tensor_operation::device::DeviceGemmMultipleD_Xdl_CShuffle<
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
  DistanceFusedCDEOp<float, FinOpT, distance_kind>,
  ck::tensor_operation::device::GemmSpecialization::MNKPadding,
  1, 256, 256, 128, 32, 4, 4, 32, 32, 4, 2,
  ck::Sequence<4, 64, 1>, ck::Sequence<1, 0, 2>, ck::Sequence<1, 0, 2>, 2, 4, 4, 1,
  ck::Sequence<4, 64, 1>, ck::Sequence<1, 0, 2>, ck::Sequence<1, 0, 2>, 2, 4, 4, 1,
  1, 1, ck::Sequence<1, 32, 1, 8>, 4>;

// Per-row argmin of the [M,N] distance matrix dist (row-major, stride n) into
// the fused-NN output via raft's ReduceOpT. One block reduces one row; ties go
// to the lowest column index (a left-to-right strict-less scan). redOp applies
// the per-row mutex update exactly as the SIMT updateReducedVal does; with one
// block per row and a single writer (thread 0) the mutex is uncontended but
// kept for parity with raft's reduce-op contract.
template <typename DataT, typename OutT, typename IdxT, typename ReduceOpT, int BlockSize>
__global__ void row_argmin_kernel(
  OutT* min, const DataT* dist, IdxT m, IdxT n, int* mutex, ReduceOpT redOp)
{
  using KVP = raft::KeyValuePair<IdxT, DataT>;

  __shared__ DataT s_val[BlockSize];
  __shared__ IdxT s_key[BlockSize];

  const IdxT row = static_cast<IdxT>(blockIdx.x);
  if (row >= m) { return; }

  const DataT* row_ptr = dist + static_cast<std::size_t>(row) * static_cast<std::size_t>(n);

  DataT best_val = std::numeric_limits<DataT>::max();
  IdxT best_key  = 0;
  for (IdxT c = threadIdx.x; c < n; c += BlockSize) {
    DataT v = row_ptr[c];
    if (v < best_val) {
      best_val = v;
      best_key = c;
    }
  }
  s_val[threadIdx.x] = best_val;
  s_key[threadIdx.x] = best_key;
  __syncthreads();

  for (int stride = BlockSize / 2; stride > 0; stride >>= 1) {
    if (threadIdx.x < stride) {
      DataT ov = s_val[threadIdx.x + stride];
      IdxT ok  = s_key[threadIdx.x + stride];
      // strict-less keeps the lower column index on a tie (ok > current key)
      if (ov < s_val[threadIdx.x]) {
        s_val[threadIdx.x] = ov;
        s_key[threadIdx.x] = ok;
      }
    }
    __syncthreads();
  }

  if (threadIdx.x == 0) {
    KVP res{s_key[0], s_val[0]};
    while (atomicCAS(mutex + row, 0, 1) == 1)
      ;
    __threadfence();
    redOp(row, min + row, res);
    __threadfence();
    atomicCAS(mutex + row, 1, 0);
  }
}

}  // namespace ck_fused_nn

// Which fused-NN metrics have a CK MFMA implementation. Mirrors the CUTLASS twin
// (L2 expanded + cosine); anything else takes the SIMT fallback.
inline bool fused_nn_ck_metric_supported(raft::distance::DistanceType metric)
{
  return metric == raft::distance::DistanceType::L2Expanded ||
         metric == raft::distance::DistanceType::L2SqrtExpanded ||
         metric == raft::distance::DistanceType::CosineExpanded;
}

// Runtime gate, mirroring pairwise_matrix_ck_can_dispatch: fp32 inputs, the CK
// instance needs N%4==0 / K%4==0 (vector loads), and the norms must be present.
// Also gated on CK arch support: DeviceFusedNNGemm uses MPerXDL=32/NPerXDL=32
// (gfx90a MFMA), which CK does not support on gfx11 (RDNA3/gfx1100 -- WMMA not
// MFMA). On gfx1100 this check returns false and the SIMT fallback is used.
// Anything else falls back to the SIMT fused-NN kernel.
template <typename DataT, typename IdxT>
bool fused_nn_ck_can_dispatch(
  IdxT m, IdxT n, IdxT k, const DataT* xn, const DataT* yn, raft::distance::DistanceType metric)
{
  if (!std::is_same_v<DataT, float>) { return false; }
  if (!fused_nn_ck_metric_supported(metric)) { return false; }
  if (xn == nullptr || yn == nullptr) { return false; }
  if (m <= 0 || n <= 0 || k <= 0) { return false; }
  if ((n % 4 != 0) || (k % 4 != 0)) { return false; }
  // DeviceFusedNNGemm uses MPerXDL=32, NPerXDL=32: only supported on gfx90a/CDNA.
  if (!ck::is_xdl_wmma_supported<float, float, 32, 32>()) { return false; }
  return true;
}

// CK fused distance + 1-NN. Computes D[m,n] via the CK MFMA GEMM, then reduces
// each row to its argmin into `min` via redOp. Inputs are row-major: x is [m,k],
// y is [n,k]; xn/yn are the per-row/per-col squared L2 norms. The caller has
// already memset the mutex workspace and, if requested, initialized `min`.
template <typename DataT,
          typename OutT,
          typename IdxT,
          typename ReduceOpT,
          typename KVPReduceOpT>
void fusedDistanceNN_ck_dispatch(OutT* min,
                                 const DataT* x,
                                 const DataT* y,
                                 const DataT* xn,
                                 const DataT* yn,
                                 IdxT m,
                                 IdxT n,
                                 IdxT k,
                                 int* workspace,
                                 ReduceOpT redOp,
                                 KVPReduceOpT pairRedOp,
                                 bool sqrt,
                                 raft::distance::DistanceType metric,
                                 cudaStream_t stream)
{
  static_assert(std::is_same_v<DataT, float>, "CK fused-NN path is fp32 only");

  // pairRedOp is the SIMT path's intra-row KVP merge; the CK path folds the
  // per-row argmin into row_argmin_kernel and only needs redOp for the final
  // store, so pairRedOp is unused here. Kept in the signature for call-site
  // parity with the SIMT impl.
  (void)pairRedOp;

  const int M = static_cast<int>(m);
  const int N = static_cast<int>(n);
  const int K = static_cast<int>(k);

  const int StrideA = K;  // X[M,K] row-major
  const int StrideB = K;  // Y[N,K] row-major == B[K,N] col-major
  const int StrideE = N;  // D[M,N] row-major

  // Materialize the distance matrix D[M,N] (transient).
  rmm::device_uvector<float> dist(static_cast<std::size_t>(M) * static_cast<std::size_t>(N),
                                  stream);
  rmm::device_uvector<float> d0(static_cast<std::size_t>(M) * static_cast<std::size_t>(N), stream);
  {
    const std::size_t total = static_cast<std::size_t>(M) * static_cast<std::size_t>(N);
    const int block         = 256;
    const std::size_t grid_sz =
      std::min<std::size_t>((total + block - 1) / block, static_cast<std::size_t>(65535));
    ck_fused_nn::broadcast_row_norm_kernel<float, IdxT>
      <<<static_cast<unsigned>(grid_sz), block, 0, stream>>>(
        d0.data(), xn, static_cast<IdxT>(M), static_cast<IdxT>(N));
    RAFT_CUDA_TRY(cudaPeekAtLastError());
  }

  raft::identity_op fin_op{};
  using FinOpT = raft::identity_op;

  auto run_gemm = [&](auto kind_const) {
    constexpr int kind = decltype(kind_const)::value;
    using DeviceOp     = ck_fused_nn::DeviceFusedNNGemm<kind, FinOpT>;
    using CDEOp        = ck_fused_nn::DistanceFusedCDEOp<float, FinOpT, kind>;
    auto device_op     = DeviceOp{};
    auto invoker       = device_op.MakeInvoker();
    auto cde_op        = CDEOp{fin_op, sqrt};
    auto argument      = device_op.MakeArgument(
      x,
      y,
      std::array<const void*, 2>{d0.data(), yn},
      dist.data(),
      M, N, K,
      StrideA, StrideB,
      std::array<ck::index_t, 2>{N, 0},  // d0 full [M,N] (stride N); d1 broadcast (stride 0)
      StrideE,
      ck_fused_nn::PassThrough{}, ck_fused_nn::PassThrough{}, cde_op);
    RAFT_EXPECTS(device_op.IsSupportedArgument(argument),
                 "raft CK fused-NN: arguments not supported by the CK instance");
    invoker.Run(argument, StreamConfig{stream, false});
  };

  if (metric == raft::distance::DistanceType::CosineExpanded) {
    run_gemm(std::integral_constant<int, 1>{});
  } else {
    run_gemm(std::integral_constant<int, 0>{});
  }

  // Per-row argmin into the output. One block (256 threads) per row.
  constexpr int kBlock = 256;
  ck_fused_nn::row_argmin_kernel<float, OutT, IdxT, ReduceOpT, kBlock>
    <<<static_cast<unsigned>(M), kBlock, 0, stream>>>(
      min, dist.data(), static_cast<IdxT>(M), static_cast<IdxT>(N), workspace, redOp);
  RAFT_CUDA_TRY(cudaPeekAtLastError());
}

}  // namespace raft::distance::detail

#endif  // defined(__HIP_PLATFORM_AMD__)

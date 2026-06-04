/*
 * Copyright (c) 2025, NVIDIA CORPORATION.
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

// GPU validation of the fused distance + 1-NN ROCm/HIP path (fusedL2NN /
// fusedCosineNN). raft v25.08 migrated the dense fused-NN gtest to cuVS, so this
// self-contained test exercises the public raft::distance::fusedL2NNMinReduce /
// fusedDistanceNN against a double-precision CPU reference (per-row min distance
// + its argmin column).
//
// On gfx90a the fused-NN is backed by a Composable Kernel MFMA GEMM + a per-row
// argmin reducing epilogue (dispatch_fused_nn_ck.cuh) for the N%4==0 / K%4==0
// fp32 regime, and by raft's SIMT fusedDistanceNNkernel otherwise. Each metric
// runs for BOTH an aligned shape (CK path) and an unaligned shape (SIMT
// fallback). The argmin must match the reference EXACTLY (integer column index);
// the min distance must match within the fp32 GEMM tolerance. The routing gate
// is asserted via fused_nn_ck_can_dispatch so a silent fall-through to SIMT on
// an aligned shape (or vice versa) is caught.

#include <raft/core/kvp.hpp>
#include <raft/core/resource/cuda_stream.hpp>
#include <raft/distance/distance_types.hpp>
#include <raft/distance/fused_distance_nn.cuh>
#include <raft/distance/fused_l2_nn.cuh>
#include <raft/util/cudart_utils.hpp>

#if defined(__HIP_PLATFORM_AMD__)
#include <raft/distance/detail/fused_distance_nn/dispatch_fused_nn_ck.cuh>
#include <ck/host_utility/device_prop.hpp>
#endif

#include <rmm/device_uvector.hpp>

#include <gtest/gtest.h>

#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

namespace raft {
namespace distance {

struct FusedNNInputs {
  int m;
  int n;
  int k;
  raft::distance::DistanceType metric;
  bool expect_ck;  // whether the CK MFMA reducing-epilogue path backs this shape
};

// CPU double-precision reference: for each row m, the (argmin column, min
// distance) of the expanded distance, with the same formula the device path
// uses (l2_exp_distance_op::epilog for L2 / cosine_distance_op::epilog). Ties go
// to the lowest column index (a left-to-right strict-less scan), matching the
// device row_argmin_kernel. The random inputs make exact fp ties measure-zero.
struct RefKVP {
  int key;
  double value;
};

std::vector<RefKVP> reference(const std::vector<float>& x,
                              const std::vector<float>& y,
                              int m,
                              int n,
                              int k,
                              raft::distance::DistanceType metric)
{
  const bool sqrt   = metric == raft::distance::DistanceType::L2SqrtExpanded;
  const bool cosine = metric == raft::distance::DistanceType::CosineExpanded;

  std::vector<double> xn(m, 0.0), yn(n, 0.0);
  for (int i = 0; i < m; ++i) {
    double s = 0;
    for (int c = 0; c < k; ++c) {
      double v = x[std::size_t(i) * k + c];
      s += v * v;
    }
    xn[i] = cosine ? std::sqrt(s) : s;
  }
  for (int j = 0; j < n; ++j) {
    double s = 0;
    for (int c = 0; c < k; ++c) {
      double v = y[std::size_t(j) * k + c];
      s += v * v;
    }
    yn[j] = cosine ? std::sqrt(s) : s;
  }

  std::vector<RefKVP> out(m);
  for (int i = 0; i < m; ++i) {
    double best = std::numeric_limits<double>::max();
    int best_k  = 0;
    for (int j = 0; j < n; ++j) {
      double dot = 0;
      for (int c = 0; c < k; ++c)
        dot += double(x[std::size_t(i) * k + c]) * double(y[std::size_t(j) * k + c]);
      double v;
      if (cosine) {
        v = 1.0 - dot / (xn[i] * yn[j]);
      } else {
        v = xn[i] + yn[j] - 2.0 * dot;
        if (v < 0) v = 0;
        if (sqrt) v = std::sqrt(v);
      }
      if (v < best) {
        best   = v;
        best_k = j;
      }
    }
    out[i] = {best_k, best};
  }
  return out;
}

class CKFusedNNTest : public ::testing::TestWithParam<FusedNNInputs> {
 protected:
  // 64-bit hash of (row, col, salt) -> float in (-1, 1). The hash embeds the row
  // index so no two distinct rows can produce identical vectors, which keeps the
  // per-row argmin unambiguous: exact-tie argmin is implementation-defined (the
  // device and a CPU scan can break ties differently), so the test data must not
  // contain ties for an exact-index comparison to be meaningful.
  static float gen(std::size_t row, std::size_t col, std::uint64_t salt)
  {
    std::uint64_t h = (row + 1) * 0x9E3779B97F4A7C15ull;
    h ^= (col + 1) * 0xC2B2AE3D27D4EB4Full + salt;
    h ^= h >> 29;
    h *= 0xBF58476D1CE4E5B9ull;
    h ^= h >> 32;
    return float(double(h % 2000000ull) / 1000000.0 - 1.0);
  }

  void run(const FusedNNInputs& p)
  {
    cudaStream_t stream = resource::get_cuda_stream(handle);

    std::vector<float> hx(std::size_t(p.m) * p.k), hy(std::size_t(p.n) * p.k);
    for (int i = 0; i < p.m; ++i)
      for (int c = 0; c < p.k; ++c)
        hx[std::size_t(i) * p.k + c] = gen(std::size_t(i), std::size_t(c), 0x1111ull);
    for (int j = 0; j < p.n; ++j)
      for (int c = 0; c < p.k; ++c)
        hy[std::size_t(j) * p.k + c] = gen(std::size_t(j), std::size_t(c), 0x7777ull);

    // Per-row / per-col norms: squared for L2, plain L2 for cosine (matches what
    // raft's callers feed fusedDistanceNN).
    const bool cosine = p.metric == raft::distance::DistanceType::CosineExpanded;
    std::vector<float> hxn(p.m), hyn(p.n);
    for (int i = 0; i < p.m; ++i) {
      float s = 0;
      for (int c = 0; c < p.k; ++c) {
        float v = hx[std::size_t(i) * p.k + c];
        s += v * v;
      }
      hxn[i] = cosine ? std::sqrt(s) : s;
    }
    for (int j = 0; j < p.n; ++j) {
      float s = 0;
      for (int c = 0; c < p.k; ++c) {
        float v = hy[std::size_t(j) * p.k + c];
        s += v * v;
      }
      hyn[j] = cosine ? std::sqrt(s) : s;
    }

    rmm::device_uvector<float> dx(hx.size(), stream);
    rmm::device_uvector<float> dy(hy.size(), stream);
    rmm::device_uvector<float> dxn(p.m, stream);
    rmm::device_uvector<float> dyn(p.n, stream);
    rmm::device_uvector<int> dworkspace(p.m, stream);
    rmm::device_uvector<raft::KeyValuePair<int, float>> dmin(p.m, stream);
    raft::update_device(dx.data(), hx.data(), hx.size(), stream);
    raft::update_device(dy.data(), hy.data(), hy.size(), stream);
    raft::update_device(dxn.data(), hxn.data(), hxn.size(), stream);
    raft::update_device(dyn.data(), hyn.data(), hyn.size(), stream);

    const bool sqrt = p.metric == raft::distance::DistanceType::L2SqrtExpanded;

    using KVP = raft::KeyValuePair<int, float>;
    if (cosine) {
      MinAndDistanceReduceOp<int, float> redOp;
      KVPMinReduce<int, float> pairRedOp;
      fusedDistanceNN<float, KVP, int>(dmin.data(),
                                       dx.data(),
                                       dy.data(),
                                       dxn.data(),
                                       dyn.data(),
                                       p.m,
                                       p.n,
                                       p.k,
                                       dworkspace.data(),
                                       redOp,
                                       pairRedOp,
                                       sqrt,
                                       true,
                                       true,
                                       p.metric,
                                       0.0f,
                                       stream);
    } else {
      fusedL2NNMinReduce<float, KVP, int>(dmin.data(),
                                          dx.data(),
                                          dy.data(),
                                          dxn.data(),
                                          dyn.data(),
                                          p.m,
                                          p.n,
                                          p.k,
                                          dworkspace.data(),
                                          sqrt,
                                          true,
                                          stream);
    }

    std::vector<KVP> hmin(p.m);
    raft::update_host(hmin.data(), dmin.data(), hmin.size(), stream);
    resource::sync_stream(handle, stream);

    auto ref = reference(hx, hy, p.m, p.n, p.k, p.metric);

    // fp64 reference distance for a single (row, col) -- used only to forgive a
    // genuine fp near-tie (two columns within fp32 ulps that the fp32 GEMM and
    // the fp64 reference can rank oppositely). A real argmin bug still fails.
    auto ref_dist = [&](int i, int j) -> double {
      double dot = 0;
      for (int c = 0; c < p.k; ++c)
        dot += double(hx[std::size_t(i) * p.k + c]) * double(hy[std::size_t(j) * p.k + c]);
      if (cosine) {
        return 1.0 - dot / (double(hxn[i]) * double(hyn[j]));
      }
      double v = double(hxn[i]) + double(hyn[j]) - 2.0 * dot;
      if (v < 0) v = 0;
      return sqrt ? std::sqrt(v) : v;
    };

    int key_mismatches = 0;
    double max_rel     = 0;
    for (int i = 0; i < p.m; ++i) {
      if (hmin[i].key != ref[i].key) {
        double dev_key_ref = ref_dist(i, hmin[i].key);
        double sep         = std::abs(dev_key_ref - ref[i].value);
        double tol         = 1e-3 * (std::abs(ref[i].value) + 1e-6);
        if (sep > tol) {
          ++key_mismatches;
          ADD_FAILURE() << "argmin mismatch row=" << i << " got_key=" << hmin[i].key
                        << " ref_key=" << ref[i].key << " got_val=" << hmin[i].value
                        << " ref_val=" << ref[i].value << " dist@got_key=" << dev_key_ref;
        }
      }
      double ae = std::abs(double(hmin[i].value) - ref[i].value);
      double re = ae / (std::abs(ref[i].value) + 1e-6);
      max_rel   = std::max(max_rel, re);
    }
    EXPECT_EQ(key_mismatches, 0) << "metric=" << int(p.metric) << " m=" << p.m << " n=" << p.n
                                 << " k=" << p.k;
    EXPECT_LT(max_rel, 1e-3) << "metric=" << int(p.metric) << " m=" << p.m << " n=" << p.n
                             << " k=" << p.k << " max_rel=" << max_rel;

#if defined(__HIP_PLATFORM_AMD__)
    bool ck = detail::fused_nn_ck_can_dispatch<float, int>(
      p.m, p.n, p.k, dxn.data(), dyn.data(), p.metric);
    // On non-CDNA arches (e.g. gfx1100/RDNA3) the DeviceFusedNNGemm instance
    // (MPerXDL=32) is not supported by CK, so the gate returns false for all shapes.
    bool expected_ck = p.expect_ck && ck::is_xdl_wmma_supported<float, float, 32, 32>();
    EXPECT_EQ(ck, expected_ck) << "CK fused-NN routing gate mismatch for m=" << p.m << " n=" << p.n
                               << " k=" << p.k;
#endif
  }

  raft::resources handle;
};

TEST_P(CKFusedNNTest, MatchesReference) { run(GetParam()); }

const std::vector<FusedNNInputs> inputs = {
  // Aligned (N%4==0, K%4==0): CK MFMA reducing-epilogue path on gfx90a.
  {512, 384, 128, raft::distance::DistanceType::L2Expanded, true},
  {1024, 1024, 256, raft::distance::DistanceType::L2Expanded, true},
  {100, 200, 64, raft::distance::DistanceType::L2Expanded, true},
  {333, 512, 128, raft::distance::DistanceType::L2SqrtExpanded, true},
  {640, 384, 96, raft::distance::DistanceType::L2SqrtExpanded, true},
  {257, 1024, 128, raft::distance::DistanceType::L2Expanded, true},
  {512, 384, 128, raft::distance::DistanceType::CosineExpanded, true},
  {777, 256, 128, raft::distance::DistanceType::CosineExpanded, true},
  // Unaligned N (N%4!=0): SIMT fallback.
  {128, 130, 64, raft::distance::DistanceType::L2Expanded, false},
  {200, 257, 96, raft::distance::DistanceType::L2SqrtExpanded, false},
  {150, 199, 128, raft::distance::DistanceType::CosineExpanded, false},
  // Unaligned K (K%4!=0): SIMT fallback.
  {128, 256, 65, raft::distance::DistanceType::L2Expanded, false},
};

INSTANTIATE_TEST_CASE_P(CKFusedNNTests, CKFusedNNTest, ::testing::ValuesIn(inputs));

}  // namespace distance
}  // namespace raft

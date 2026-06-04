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

// GPU validation of the expanded pairwise-distance ROCm/HIP path. raft v25.08
// migrated the dense distance gtest suite to cuVS, so this self-contained test
// exercises raft::distance::pairwise_distance for L2Expanded / L2SqrtExpanded /
// CosineExpanded and checks the result against a double-precision CPU reference.
//
// On gfx90a the expanded distances are backed by a Composable Kernel MFMA GEMM +
// fused epilogue (dispatch_ck.cuh) for the N%4==0 / K%4==0 regime, and by raft's
// SIMT/sm60 kernel otherwise. Each metric is run for BOTH an aligned shape (CK
// path) and an unaligned shape (SIMT fallback); both must match the CPU
// reference numerically, which proves the CK MFMA path agrees with the SIMT/CPU
// reference (no tolerance loosening). The routing gate itself is asserted via
// pairwise_matrix_ck_can_dispatch so a silent fall-through to SIMT on an aligned
// shape would fail the test.

#include <raft/core/resource/cuda_stream.hpp>
#include <raft/distance/distance.cuh>
#include <raft/distance/distance_types.hpp>
#include <raft/util/cudart_utils.hpp>

#if defined(__HIP_PLATFORM_AMD__)
#include <raft/distance/detail/pairwise_matrix/dispatch_ck.cuh>
#include <raft/distance/detail/distance_ops/cosine.cuh>
#include <raft/distance/detail/distance_ops/l2_exp.cuh>
#include <ck/host_utility/device_prop.hpp>
#endif

#include <rmm/device_uvector.hpp>

#include <gtest/gtest.h>

#include <cmath>
#include <cstdint>
#include <vector>

namespace raft {
namespace distance {

struct CKDistInputs {
  int m;
  int n;
  int k;
  raft::distance::DistanceType metric;
  bool expect_ck;  // whether the CK MFMA path should back this shape on gfx90a
};

// CPU double-precision reference for the expanded distances. x is [m,k], y is
// [n,k], both row-major; out is [m,n] row-major.
std::vector<double> reference(const std::vector<float>& x,
                              const std::vector<float>& y,
                              int m,
                              int n,
                              int k,
                              raft::distance::DistanceType metric)
{
  std::vector<double> xn(m, 0.0), yn(n, 0.0);
  for (int i = 0; i < m; ++i) {
    double s = 0;
    for (int c = 0; c < k; ++c) {
      double v = x[std::size_t(i) * k + c];
      s += v * v;
    }
    xn[i] = s;
  }
  for (int j = 0; j < n; ++j) {
    double s = 0;
    for (int c = 0; c < k; ++c) {
      double v = y[std::size_t(j) * k + c];
      s += v * v;
    }
    yn[j] = s;
  }
  const bool sqrt   = metric == raft::distance::DistanceType::L2SqrtExpanded;
  const bool cosine = metric == raft::distance::DistanceType::CosineExpanded;
  std::vector<double> out(std::size_t(m) * n);
  for (int i = 0; i < m; ++i) {
    for (int j = 0; j < n; ++j) {
      double dot = 0;
      for (int c = 0; c < k; ++c)
        dot += double(x[std::size_t(i) * k + c]) * double(y[std::size_t(j) * k + c]);
      double v;
      if (cosine) {
        v = 1.0 - dot / (std::sqrt(xn[i]) * std::sqrt(yn[j]));
      } else {
        v = xn[i] + yn[j] - 2.0 * dot;
        if (v < 0) v = 0;
        if (sqrt) v = std::sqrt(v);
      }
      out[std::size_t(i) * n + j] = v;
    }
  }
  return out;
}

class CKDistanceTest : public ::testing::TestWithParam<CKDistInputs> {
 protected:
  void run(const CKDistInputs& p)
  {
    cudaStream_t stream = resource::get_cuda_stream(handle);

    std::vector<float> hx(std::size_t(p.m) * p.k), hy(std::size_t(p.n) * p.k);
    for (std::size_t i = 0; i < hx.size(); ++i)
      hx[i] = float((i * 2654435761u) % 1000) / 500.0f - 1.0f;
    for (std::size_t i = 0; i < hy.size(); ++i)
      hy[i] = float((i * 40503u + 7u) % 1000) / 500.0f - 1.0f;

    rmm::device_uvector<float> dx(hx.size(), stream);
    rmm::device_uvector<float> dy(hy.size(), stream);
    rmm::device_uvector<float> dout(std::size_t(p.m) * p.n, stream);
    raft::update_device(dx.data(), hx.data(), hx.size(), stream);
    raft::update_device(dy.data(), hy.data(), hy.size(), stream);

    raft::distance::pairwise_distance<float, int>(
      handle, dx.data(), dy.data(), dout.data(), p.m, p.n, p.k, p.metric, true);

    std::vector<float> hout(std::size_t(p.m) * p.n);
    raft::update_host(hout.data(), dout.data(), hout.size(), stream);
    resource::sync_stream(handle, stream);

    auto ref = reference(hx, hy, p.m, p.n, p.k, p.metric);

    double max_abs = 0, max_rel = 0;
    for (std::size_t i = 0; i < hout.size(); ++i) {
      double got = hout[i], exp = ref[i];
      double ae = std::abs(got - exp);
      double re = ae / (std::abs(exp) + 1e-6);
      max_abs   = std::max(max_abs, ae);
      max_rel   = std::max(max_rel, re);
    }
    // fp32 GEMM accumulation: a few ulp of relative error is expected.
    EXPECT_LT(max_rel, 1e-3) << "metric=" << int(p.metric) << " m=" << p.m << " n=" << p.n
                             << " k=" << p.k << " max_abs=" << max_abs << " max_rel=" << max_rel;

#if defined(__HIP_PLATFORM_AMD__)
    // Assert which backend handled this shape, so a silent fall-through to SIMT
    // on an aligned shape (or vice versa) is caught. Mirrors the post-flip params
    // pairwise_matrix_dispatch builds for a row-major input.
    using detail::pairwise_matrix_params;
    pairwise_matrix_params<int, float, float, raft::identity_op> params{
      p.m,         p.n,    p.k, p.k, p.k, p.n, dx.data(), dy.data(), dx.data(), dy.data(),
      dout.data(), raft::identity_op{}, true};
    bool ck = false;
    if (p.metric == raft::distance::DistanceType::CosineExpanded) {
      ck = detail::pairwise_matrix_ck_can_dispatch<
        detail::ops::cosine_distance_op<float, float, int>>(params);
    } else {
      ck = detail::pairwise_matrix_ck_can_dispatch<
        detail::ops::l2_exp_distance_op<float, float, int>>(params);
    }
    // On non-CDNA arches (e.g. gfx1100/RDNA3) the DeviceL2 instance (MPerXDL=32)
    // is not supported by CK, so the gate correctly returns false for all shapes.
    bool expected_ck = p.expect_ck && ck::is_xdl_wmma_supported<float, float, 32, 32>();
    EXPECT_EQ(ck, expected_ck) << "CK routing gate mismatch for m=" << p.m << " n=" << p.n
                               << " k=" << p.k;
#endif
  }

  raft::resources handle;
};

TEST_P(CKDistanceTest, MatchesReference) { run(GetParam()); }

const std::vector<CKDistInputs> inputs = {
  // Aligned (N%4==0, K%4==0): CK MFMA path on gfx90a.
  {512, 384, 128, raft::distance::DistanceType::L2Expanded, true},
  {1024, 1024, 256, raft::distance::DistanceType::L2Expanded, true},
  {100, 200, 64, raft::distance::DistanceType::L2Expanded, true},
  {333, 512, 128, raft::distance::DistanceType::L2SqrtExpanded, true},
  {640, 384, 96, raft::distance::DistanceType::L2SqrtExpanded, true},
  {512, 384, 128, raft::distance::DistanceType::CosineExpanded, true},
  {777, 256, 128, raft::distance::DistanceType::CosineExpanded, true},
  // Unaligned N (N%4!=0): SIMT/sm60 fallback.
  {128, 130, 64, raft::distance::DistanceType::L2Expanded, false},
  {200, 257, 96, raft::distance::DistanceType::L2SqrtExpanded, false},
  {150, 199, 128, raft::distance::DistanceType::CosineExpanded, false},
  // Unaligned K (K%4!=0): SIMT/sm60 fallback.
  {128, 256, 65, raft::distance::DistanceType::L2Expanded, false},
};

INSTANTIATE_TEST_CASE_P(CKDistanceTests, CKDistanceTest, ::testing::ValuesIn(inputs));

}  // namespace distance
}  // namespace raft

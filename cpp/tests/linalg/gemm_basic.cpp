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

// clang-format off
// MIT License
//
// Modifications Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// clang-format on

#include <raft/core/copy.hpp>
#include <raft/core/device_mdarray.hpp>
#include <raft/core/host_mdarray.hpp>
#include <raft/core/resource/cuda_stream.hpp>
#include <raft/core/resources.hpp>
#include <raft/linalg/gemm.hpp>

#include <gtest/gtest.h>

#include <vector>

namespace raft::linalg {

// Matrix dimensions: A (2x3) * B (3x2) = C (2x2)
constexpr int M = 2, N = 2, K = 3;

// Non-trivial alpha and beta constants
float alpha_val = 2.0f;
float beta_val  = 3.0f;

// Input matrices with small integer values (stored as float)
// Matrix A (2x3):
// [ 1,  2,  3]
// [ 4,  5,  6]
std::vector<float> a_host = {1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f};

// Matrix B (3x2):
// [ 7,  8]
// [ 9, 10]
// [11, 12]
std::vector<float> b_host = {7.0f, 8.0f, 9.0f, 10.0f, 11.0f, 12.0f};

// Initial matrix C (2x2):
// [1, 2]
// [3, 4]
std::vector<float> c_host = {1.0f, 2.0f, 3.0f, 4.0f};

// Result matrix (2x2):
// [119, 134]
// [287, 320]
std::vector<float> r_host_allcoefs = {119.0f, 134.0f, 287.0f, 320.0f};

// Result matrix without coefficients (2x2):
// A * B result when alpha=1 (default value), beta=3.0
// [61, 70]
// [148, 166]
std::vector<float> r_host_noalpha = {61.0f, 70.0f, 148.0f, 166.0f};

// Result matrix without coefficients (2x2):
// A * B result when beta=0 (default value), alpha=2.0
// [116, 128]
// [278, 308]
std::vector<float> r_host_nobeta = {116.0f, 128.0f, 278.0f, 308.0f};

// Result matrix without coefficients (2x2):
// A * B result when alpha=1, beta=0 (default values)
// [58, 64]
// [139, 154]
std::vector<float> r_host_nocoefs = {58.0f, 64.0f, 139.0f, 154.0f};

auto get_host_ground_truth(bool use_alpha, bool use_beta)
{
  if (use_alpha && use_beta) {
    return r_host_allcoefs;
  } else if (use_alpha) {
    return r_host_nobeta;
  } else if (use_beta) {
    return r_host_noalpha;
  } else {
    return r_host_nocoefs;
  }
}

void test_gemm_pointer_mode_host(bool use_alpha, bool use_beta)
{
  raft::resources res;
  auto stream = raft::resource::get_cuda_stream(res);

  // Create device matrices
  auto a_device = raft::make_device_matrix<float>(res, M, K);
  auto b_device = raft::make_device_matrix<float>(res, K, N);
  auto c_device = raft::make_device_matrix<float>(res, M, N);

  // Copy data to device
  raft::copy(a_device.data_handle(), a_host.data(), a_host.size(), stream);
  raft::copy(b_device.data_handle(), b_host.data(), b_host.size(), stream);
  raft::copy(c_device.data_handle(), c_host.data(), c_host.size(), stream);

  // Create scalar views for alpha and beta
  auto alpha_scalar = raft::make_host_scalar(alpha_val);
  auto beta_scalar  = raft::make_host_scalar(beta_val);

  // Perform GEMM: C = alpha * A * B + beta * C
  raft::linalg::gemm(res,
                     a_device.view(),
                     b_device.view(),
                     c_device.view(),
                     use_alpha ? std::make_optional(alpha_scalar.view()) : std::nullopt,
                     use_beta ? std::make_optional(beta_scalar.view()) : std::nullopt);

  // Copy result back to host
  std::vector<float> result(M * N);
  raft::copy(result.data(), c_device.data_handle(), result.size(), stream);
  raft::resource::sync_stream(res);

  // Compare results
  auto gt = get_host_ground_truth(use_alpha, use_beta);
  for (int i = 0; i < M * N; ++i) {
    EXPECT_FLOAT_EQ(result[i], gt[i]) << "Mismatch at index " << i;
  }
}

void test_gemm_pointer_mode_device(bool use_alpha, bool use_beta)
{
  raft::resources res;
  auto stream = raft::resource::get_cuda_stream(res);

  // Create device matrices
  auto a_device = raft::make_device_matrix<float>(res, M, K);
  auto b_device = raft::make_device_matrix<float>(res, K, N);
  auto c_device = raft::make_device_matrix<float>(res, M, N);

  // Copy data to device
  raft::copy(a_device.data_handle(), a_host.data(), a_host.size(), stream);
  raft::copy(b_device.data_handle(), b_host.data(), b_host.size(), stream);
  raft::copy(c_device.data_handle(), c_host.data(), c_host.size(), stream);

  // Create scalar views for alpha and beta
  auto alpha_scalar = raft::make_device_scalar(res, alpha_val);
  auto beta_scalar  = raft::make_device_scalar(res, beta_val);

  // Perform GEMM: C = alpha * A * B + beta * C
  raft::linalg::gemm(res,
                     a_device.view(),
                     b_device.view(),
                     c_device.view(),
                     use_alpha ? std::make_optional(alpha_scalar.view()) : std::nullopt,
                     use_beta ? std::make_optional(beta_scalar.view()) : std::nullopt);

  // Copy result back to host
  std::vector<float> result(M * N);
  raft::copy(result.data(), c_device.data_handle(), result.size(), stream);
  raft::resource::sync_stream(res);

  // Compare results
  auto gt = get_host_ground_truth(use_alpha, use_beta);
  for (int i = 0; i < M * N; ++i) {
    EXPECT_FLOAT_EQ(result[i], gt[i]) << "Mismatch at index " << i;
  }
}

/**
 * Shape- and precision-swept gemm against a host reference.
 *
 * NOTE(HIP/AMD): added because nothing here covered float64, which is how the following defect
 * shipped. hipblasLtMatmulAlgoGetHeuristic returns HIPBLAS_STATUS_SUCCESS with *zero* results when
 * Tensile has no solution for a shape -- on gfx90a that is every float64 problem with m == 1.
 * raft::linalg::detail::matmul_desc::create checked only the status, so heuristics stayed zeroed
 * and hipblasLtMatmul was handed an all-zero algo, which it dereferenced:
 * SIGSEGV in TensileLite::ContractionSolution::requiredWorkspaceSize.
 *
 * The m == 1 rows below are the regression cases -- they segfaulted before the fix. Keep both
 * precisions: float32 always gets an Lt algorithm, so only float64 exercises the fallback.
 */
template <typename T>
void test_gemm_shape(int m, int n, int k)
{
  raft::resources res;
  auto stream = raft::resource::get_cuda_stream(res);

  std::vector<T> a(static_cast<size_t>(m) * k);
  std::vector<T> b(static_cast<size_t>(k) * n);
  std::vector<T> c(static_cast<size_t>(m) * n, T(0));
  // Small distinct values, exactly representable in both precisions.
  for (size_t i = 0; i < a.size(); ++i) {
    a[i] = static_cast<T>((i % 7) + 1);
  }
  for (size_t i = 0; i < b.size(); ++i) {
    b[i] = static_cast<T>((i % 5) + 1);
  }

  auto a_device = raft::make_device_matrix<T>(res, m, k);
  auto b_device = raft::make_device_matrix<T>(res, k, n);
  auto c_device = raft::make_device_matrix<T>(res, m, n);
  raft::copy(a_device.data_handle(), a.data(), a.size(), stream);
  raft::copy(b_device.data_handle(), b.data(), b.size(), stream);
  raft::copy(c_device.data_handle(), c.data(), c.size(), stream);

  raft::linalg::gemm(res, a_device.view(), b_device.view(), c_device.view());

  std::vector<T> result(static_cast<size_t>(m) * n);
  raft::copy(result.data(), c_device.data_handle(), result.size(), stream);
  raft::resource::sync_stream(res);

  // Row-major reference: C[i][j] = sum_p A[i][p] * B[p][j]
  for (int i = 0; i < m; ++i) {
    for (int j = 0; j < n; ++j) {
      T expected = T(0);
      for (int p = 0; p < k; ++p) {
        expected += a[static_cast<size_t>(i) * k + p] * b[static_cast<size_t>(p) * n + j];
      }
      EXPECT_NEAR(static_cast<double>(result[static_cast<size_t>(i) * n + j]),
                  static_cast<double>(expected),
                  1e-6)
        << "Mismatch at (" << i << ", " << j << ") for m=" << m << " n=" << n << " k=" << k;
    }
  }
}

#define RAFT_GEMM_SHAPE_TESTS(SUFFIX, TYPE)                                                       \
  TEST(Raft, GemmShapeSquare##SUFFIX) { test_gemm_shape<TYPE>(64, 64, 64); }                      \
  TEST(Raft, GemmShapeTall##SUFFIX) { test_gemm_shape<TYPE>(500, 10, 10); }                       \
  /* m == 1: no hipBLASLt solution in float64; these segfaulted before the fallback was added. */ \
  TEST(Raft, GemmShapeSingleRow##SUFFIX) { test_gemm_shape<TYPE>(1, 1, 10); }                     \
  TEST(Raft, GemmShapeSingleRowWide##SUFFIX) { test_gemm_shape<TYPE>(1, 10, 10); }                \
  TEST(Raft, GemmShapeSingleRowWider##SUFFIX) { test_gemm_shape<TYPE>(1, 500, 10); }              \
  TEST(Raft, GemmShapeScalar##SUFFIX) { test_gemm_shape<TYPE>(1, 1, 1); }                         \
  TEST(Raft, GemmShapeSingleCol##SUFFIX) { test_gemm_shape<TYPE>(10, 1, 10); }                    \
  TEST(Raft, GemmShapeSingleK##SUFFIX) { test_gemm_shape<TYPE>(10, 10, 1); }

RAFT_GEMM_SHAPE_TESTS(F32, float)
RAFT_GEMM_SHAPE_TESTS(F64, double)

#undef RAFT_GEMM_SHAPE_TESTS

TEST(Raft, GemmPointerModeHost) { test_gemm_pointer_mode_host(true, true); }
TEST(Raft, GemmPointerModeHostAlpha) { test_gemm_pointer_mode_host(true, false); }
TEST(Raft, GemmPointerModeHostBeta) { test_gemm_pointer_mode_host(false, true); }
TEST(Raft, GemmPointerModeHostDefaults) { test_gemm_pointer_mode_host(false, false); }
TEST(Raft, GemmPointerModeDevice) { test_gemm_pointer_mode_device(true, true); }
TEST(Raft, GemmPointerModeDeviceAlpha) { test_gemm_pointer_mode_device(true, false); }
TEST(Raft, GemmPointerModeDeviceBeta) { test_gemm_pointer_mode_device(false, true); }
TEST(Raft, GemmPointerModeDeviceDefaults) { test_gemm_pointer_mode_device(false, false); }

}  // namespace raft::linalg

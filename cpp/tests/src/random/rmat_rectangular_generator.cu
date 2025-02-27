/*
 * Copyright (c) 2022-2024, NVIDIA CORPORATION.
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

/*
 * MIT LICENSE
 * Copyright (c) 2025 Advanced Micro Devices, Inc.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <raft/core/resource/cuda_stream.hpp>
#include <raft/core/resources.hpp>
#include <raft/random/rng.cuh>

#include <raft_runtime/random/rmat_rectangular_generator.hpp>

#include <gtest/gtest.h>
#include <test_utils.cuh>

#include <vector>

namespace raft {
namespace random {

struct RmatInputs {
  size_t r_scale;
  size_t c_scale;
  size_t n_edges;
  uint64_t seed;
  float eps;
};

template <typename OutT, typename InT>
__global__ void normalize_kernel(
  OutT* theta, const InT* in_vals, int max_scale, int r_scale, int c_scale)
{
  const int idx = threadIdx.x;
  if (idx < max_scale) {
    auto a   = OutT(in_vals[4 * idx]);
    auto b   = OutT(in_vals[4 * idx + 1]);
    auto c   = OutT(in_vals[4 * idx + 2]);
    auto d   = OutT(in_vals[4 * idx + 3]);
    auto sum = a + b + c + d;
    a /= sum;
    b /= sum;
    c /= sum;
    d /= sum;
    theta[4 * idx + 0] = a;
    theta[4 * idx + 1] = b;
    theta[4 * idx + 2] = c;
    theta[4 * idx + 3] = d;
  }
}

template <typename OutT>
__global__ void handle_rect_kernel(OutT* theta, int max_scale, int r_scale, int c_scale)
{
  const int idx = threadIdx.x;
  if (idx < max_scale) {
    auto a = theta[4 * idx + 0];
    auto b = theta[4 * idx + 1];
    auto c = theta[4 * idx + 2];
    auto d = theta[4 * idx + 3];
    if (idx >= r_scale) {
      a += c;
      c = OutT(0);
      b += d;
      d = OutT(0);
    }
    if (idx >= c_scale) {
      a += b;
      b = OutT(0);
      c += d;
      d = OutT(0);
    }
    theta[4 * idx + 0] = a;
    theta[4 * idx + 1] = b;
    theta[4 * idx + 2] = c;
    theta[4 * idx + 3] = d;
  }
}

template <typename OutT, typename InT>
void normalize(OutT* theta,
               const InT* in_vals,
               int max_scale,
               int r_scale,
               int c_scale,
               bool do_rect,
               cudaStream_t stream)
{
  normalize_kernel<OutT, InT><<<1, 256, 0, stream>>>(theta, in_vals, max_scale, r_scale, c_scale);
  RAFT_CUDA_TRY(cudaGetLastError());
  if (do_rect) {
    handle_rect_kernel<<<1, 256, 0, stream>>>(theta, max_scale, r_scale, c_scale);
    RAFT_CUDA_TRY(cudaGetLastError());
  }
}
template <typename OutT>
__global__ void compute_hist(
  int* hist, const OutT* out, int len, OutT max_scale, OutT r_scale, OutT c_scale)
{
  const int idx = (blockIdx.x * blockDim.x + threadIdx.x) * 2;
  if ((idx + 1) < len) {
    const int src = out[idx];
    const int dst = out[idx + 1];
    for (size_t bit_pos = 0; bit_pos < max_scale; ++bit_pos) {
      bool src_bit = bit_pos < r_scale ? src & (1 << bit_pos) : 0;
      bool dst_bit = bit_pos < c_scale ? dst & (1 << bit_pos) : 0;
      auto idx     = bit_pos * 4 + src_bit * 2 + dst_bit;
      atomicAdd(hist + idx, 1);
    }
  }
}

template <typename OutT, typename ThetaT>
class RmatGenTypedTest : public ::testing::TestWithParam<RmatInputs> {
 public:
  RmatGenTypedTest()
    : handle{},
      stream{raft::resource::get_cuda_stream(handle)},
      params{GetParam()},
      out{params.n_edges * 2, stream},
      out_src{params.n_edges, stream},
      out_dst{params.n_edges, stream},
      theta{0, stream},
      h_theta{},
      state{params.seed, raft::random::GeneratorType::GenPC},
      max_scale{static_cast<int>(std::max(params.r_scale, params.c_scale))}
  {
    theta.resize(4 * max_scale, stream);

    raft::random::uniform<ThetaT>(handle, state, theta.data(), theta.size(), ThetaT(0), ThetaT(1));

    normalize<ThetaT, ThetaT>(theta.data(),
                              theta.data(),
                              max_scale,
                              static_cast<int>(params.r_scale),
                              static_cast<int>(params.c_scale),
                              (params.r_scale != params.c_scale),
                              stream);

    h_theta.resize(theta.size());
    raft::update_host(h_theta.data(), theta.data(), theta.size(), stream);
    RAFT_CUDA_TRY(cudaStreamSynchronize(stream));
  }

 protected:
  void SetUp() override
  {
    raft::runtime::random::rmat_rectangular_gen(handle,
                                                out.data(),
                                                out_src.data(),
                                                out_dst.data(),
                                                theta.data(),
                                                params.r_scale,
                                                params.c_scale,
                                                params.n_edges,
                                                state);

    RAFT_CUDA_TRY(cudaStreamSynchronize(stream));
  }

  void validate()
  {
    // Can't use OutT here as the hist data type since there is a call to atomic
    // add. AtomicAdd does not support long/int64_t.
    rmm::device_uvector<int> hist(theta.size(), stream);
    RAFT_CUDA_TRY(cudaMemsetAsync(hist.data(), 0, hist.size() * sizeof(int), stream));

    compute_hist<<<raft::ceildiv<int>(static_cast<int>(out.size() / 2), 128), 128, 0, stream>>>(
      hist.data(),
      out.data(),
      static_cast<int>(out.size()),
      static_cast<OutT>(max_scale),
      static_cast<OutT>(params.r_scale),
      static_cast<OutT>(params.c_scale));
    RAFT_CUDA_TRY(cudaGetLastError());

    rmm::device_uvector<ThetaT> computed_theta(theta.size(), stream);

    normalize<ThetaT, int>(computed_theta.data(),
                           hist.data(),
                           max_scale,
                           static_cast<int>(params.r_scale),
                           static_cast<int>(params.c_scale),
                           false,
                           stream);
    RAFT_CUDA_TRY(cudaStreamSynchronize(stream));

    ASSERT_TRUE(devArrMatchHost(
      h_theta.data(), computed_theta.data(), theta.size(), CompareApprox<ThetaT>(params.eps)));
  }

 protected:
  raft::resources handle;
  cudaStream_t stream;
  RmatInputs params;

  rmm::device_uvector<OutT> out, out_src, out_dst;
  rmm::device_uvector<ThetaT> theta;
  std::vector<ThetaT> h_theta;

  raft::random::RngState state;
  int max_scale;
};

static const float TOLERANCE                = 0.01f;
static const std::vector<RmatInputs> inputs = {
  {16, 16, 100000, 123456ULL, TOLERANCE},
  {16, 16, 200000, 123456ULL, TOLERANCE},
  {18, 18, 100000, 123456ULL, TOLERANCE},
  {18, 18, 200000, 123456ULL, TOLERANCE},
  {16, 16, 100000, 456789ULL, TOLERANCE},
  {16, 16, 200000, 456789ULL, TOLERANCE},
  {18, 18, 100000, 456789ULL, TOLERANCE},
  {18, 18, 200000, 456789ULL, TOLERANCE},
  {16, 18, 200000, 123456ULL, TOLERANCE},
  {18, 16, 200000, 123456ULL, TOLERANCE},
  {16, 18, 200000, 456789ULL, TOLERANCE},
  {18, 16, 200000, 456789ULL, TOLERANCE},
};

using RmatGenTest_int_float = RmatGenTypedTest<int, float>;
TEST_P(RmatGenTest_int_float, Result) { validate(); }
INSTANTIATE_TEST_SUITE_P(RmatGen_int_float, RmatGenTest_int_float, ::testing::ValuesIn(inputs));

using RmatGenTest_int_double = RmatGenTypedTest<int, double>;
TEST_P(RmatGenTest_int_double, Result) { validate(); }
INSTANTIATE_TEST_SUITE_P(RmatGen_int_double, RmatGenTest_int_double, ::testing::ValuesIn(inputs));

using RmatGenTest_int64_float = RmatGenTypedTest<int64_t, float>;
TEST_P(RmatGenTest_int64_float, Result) { validate(); }
INSTANTIATE_TEST_SUITE_P(RmatGen_int64_float, RmatGenTest_int64_float, ::testing::ValuesIn(inputs));

using RmatGenTest_int64_double = RmatGenTypedTest<int64_t, double>;
TEST_P(RmatGenTest_int64_double, Result) { validate(); }
INSTANTIATE_TEST_SUITE_P(RmatGen_int64_double,
                         RmatGenTest_int64_double,
                         ::testing::ValuesIn(inputs));

}  // namespace random
}  // namespace raft

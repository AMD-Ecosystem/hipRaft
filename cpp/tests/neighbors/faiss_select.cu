// MIT License
//
// Copyright (c) 2025 Advanced Micro Devices, Inc.
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

#include "../test_utils.cuh"

#include <raft/neighbors/detail/faiss_select/Comparators.cuh>
#include <raft/neighbors/detail/faiss_select/Select.cuh>
#include <raft/util/cuda_dev_essentials.cuh>
#include <raft/util/cudart_utils.hpp>

#include <rmm/cuda_stream_view.hpp>
#include <rmm/device_uvector.hpp>

#include <gtest/gtest.h>

#include <cstddef>
#include <cstdint>
#include <limits>
#include <vector>

template <int NumWarpQ, int NumThreadQ, int ThreadsPerBlock>
__global__ void entry_point(int32_t* keys, float* values, size_t N, int k)
{
  constexpr bool Dir = true;
  using Comparator   = raft::neighbors::detail::faiss_select::Comparator<int32_t>;
  typedef raft::neighbors::detail::faiss_select::
    WarpSelect<int32_t, float, Dir, Comparator, NumWarpQ, NumThreadQ, ThreadsPerBlock>
      WarpSelectType;
  WarpSelectType heap(std::numeric_limits<int32_t>::min(), std::numeric_limits<float>::max(), k);
  size_t index = raft::laneId();
  if (index < N) { heap.addThreadQ(keys[index], values[index]); }
  heap.reduce();
  heap.writeOut(keys, values, k);
}

struct WarpSelectParameters {
  size_t array_size;
  int k;
};

class WarpSelectParameterized : public ::testing::TestWithParam<WarpSelectParameters> {
 protected:
  template <int NumWarpQ, int NumThreadQ, int ThreadsPerBlock>
  void InternalTestBody()
  {
    WarpSelectParameters const& parameters = GetParam();

    ASSERT_TRUE(ThreadsPerBlock >= parameters.array_size);
    ASSERT_TRUE(ThreadsPerBlock <= raft::host_warp_size(0));

    std::vector<int32_t> h_keys(parameters.array_size);
    std::vector<float> h_values(parameters.array_size);

    // Generate a monotonically increasing sequence
    // h_keys   = [0, 1, 2 ... N]
    // h_values = [0, 1, 2 ... N]
    std::iota(std::begin(h_keys), std::end(h_keys), 0);
    std::iota(std::begin(h_values), std::end(h_values), 0);

    rmm::device_uvector<int32_t> d_keys(parameters.array_size, rmm::cuda_stream_default);
    rmm::device_uvector<float> d_values(parameters.array_size, rmm::cuda_stream_default);

    raft::copy(d_keys.data(), h_keys.data(), parameters.array_size, rmm::cuda_stream_default);
    raft::copy(d_values.data(), h_values.data(), parameters.array_size, rmm::cuda_stream_default);

    dim3 block(ThreadsPerBlock);
    dim3 grid(1);
    entry_point<NumWarpQ, NumThreadQ, ThreadsPerBlock>
      <<<grid, block, 0, rmm::cuda_stream_default>>>(
        d_keys.data(), d_values.data(), parameters.array_size, parameters.k);

    raft::copy(h_keys.data(), d_keys.data(), parameters.array_size, rmm::cuda_stream_default);
    raft::copy(h_values.data(), d_values.data(), parameters.array_size, rmm::cuda_stream_default);
    for (size_t index = 0; index < parameters.k; ++index) {
      // Expected the largest k elements at the front
      EXPECT_EQ(h_keys[index], parameters.array_size - index - 1);
      EXPECT_EQ(h_values[index], parameters.array_size - index - 1);
    }
  }
};

class WarpSelectParameterizedTPB64 : public WarpSelectParameterized {
 protected:
  static constexpr int ThreadsPerBlock = 64;
};

TEST_P(WarpSelectParameterizedTPB64, WarpParameterCombination1)
{
  if (raft::host_warp_size(0) == 64) {
    constexpr int NumThreadQ = 2;
    constexpr int NumWarpQ   = 64;
    InternalTestBody<NumWarpQ, NumThreadQ, ThreadsPerBlock>();
  }
}

TEST_P(WarpSelectParameterizedTPB64, WarpParameterCombination2)
{
  if (raft::host_warp_size(0) == 64) {
    constexpr int NumThreadQ = 3;
    constexpr int NumWarpQ   = 128;
    InternalTestBody<NumWarpQ, NumThreadQ, ThreadsPerBlock>();
  }
}

INSTANTIATE_TEST_CASE_P(WarpSelectTests,
                        WarpSelectParameterizedTPB64,
                        ::testing::ValuesIn(std::vector<WarpSelectParameters>{
                          {.array_size = 10, .k = 3},
                          {.array_size = 10, .k = 10},
                          {.array_size = 64, .k = 2},
                        }));

class WarpSelectParameterizedTPB32 : public WarpSelectParameterized {
 protected:
  static constexpr int ThreadsPerBlock = 32;
};

TEST_P(WarpSelectParameterizedTPB32, WarpParameterCombination1)
{
  if (raft::host_warp_size(0) == 32) {
    constexpr int NumThreadQ = 3;
    constexpr int NumWarpQ   = 128;
    InternalTestBody<NumWarpQ, NumThreadQ, ThreadsPerBlock>();
  }
}

INSTANTIATE_TEST_CASE_P(WarpSelectTests,
                        WarpSelectParameterizedTPB32,
                        ::testing::ValuesIn(std::vector<WarpSelectParameters>{
                          {.array_size = 10, .k = 3}}));

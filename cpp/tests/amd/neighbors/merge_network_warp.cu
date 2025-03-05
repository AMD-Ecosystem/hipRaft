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

#include "../../test_utils.cuh"

#include <raft/neighbors/detail/faiss_select/Comparators.cuh>
#include <raft/neighbors/detail/faiss_select/MergeNetworkWarp.cuh>
#include <raft/util/cuda_dev_essentials.cuh>
#include <raft/util/cudart_utils.hpp>

#include <rmm/cuda_stream_view.hpp>
#include <rmm/device_uvector.hpp>

#include <gtest/gtest.h>

#include <cstddef>
#include <cstdint>
#include <vector>

template <int WarpQueueSize>
__global__ void entry_point(int32_t* keys, float* values, size_t N)
{
  int32_t lane_index = raft::laneId();
  int32_t local_key[WarpQueueSize]{};
  float local_value[WarpQueueSize]{};
  for (size_t offset = 0; offset < WarpQueueSize; ++offset) {
    size_t index = (offset * raft::WarpSize) + lane_index;
    if (index < N) {
      local_key[offset]   = keys[index];
      local_value[offset] = values[index];
    }
  }

  using Comparator               = raft::neighbors::detail::faiss_select::Comparator<int32_t>;
  constexpr bool kAscendingOrder = false;  // We want to sort it in descending order
  raft::neighbors::detail::faiss_select::
    warpSortAnyRegisters<int32_t, float, WarpQueueSize, kAscendingOrder, Comparator>(local_key,
                                                                                     local_value);

  for (size_t offset = 0; offset < WarpQueueSize; ++offset) {
    size_t index = (offset * raft::WarpSize) + lane_index;
    if (index < N) {
      keys[index]   = local_key[offset];
      values[index] = local_value[offset];
    }
  }
}

struct WarpSortAnyRegistersParameters {
  size_t array_size;
  size_t thread_block_size;
};

template <int Size>
class WarpSortAnyRegistersParameterized
  : public ::testing::TestWithParam<WarpSortAnyRegistersParameters> {
  static constexpr int kWarpQueueSize = Size;

 protected:
  void InternalTestBody()
  {
    WarpSortAnyRegistersParameters const& parameters = GetParam();

    ASSERT_TRUE(kWarpQueueSize * parameters.thread_block_size >= parameters.array_size);

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

    dim3 block(parameters.thread_block_size);
    dim3 grid(1);
    entry_point<kWarpQueueSize><<<grid, block, 0, rmm::cuda_stream_default>>>(
      d_keys.data(), d_values.data(), parameters.array_size);

    raft::copy(h_keys.data(), d_keys.data(), parameters.array_size, rmm::cuda_stream_default);
    raft::copy(h_values.data(), d_values.data(), parameters.array_size, rmm::cuda_stream_default);

    for (size_t index = 0; index < parameters.array_size; ++index) {
      // Expected reversed order
      EXPECT_EQ(h_keys[index], parameters.array_size - index - 1);
      EXPECT_EQ(h_values[index], parameters.array_size - index - 1);
    }
  }
};

#define STAMP_TEST_CASES(WarpQueueSize)                                                        \
  class WarpSortAnyRegistersParameterizedQueueSize##WarpQueueSize                              \
    : public WarpSortAnyRegistersParameterized<WarpQueueSize> {};                              \
  TEST_P(WarpSortAnyRegistersParameterizedQueueSize##WarpQueueSize, Test)                      \
  {                                                                                            \
    if (raft::host_warp_size(0) == 32) {                                                       \
      if (GetParam().array_size > 32) {                                                        \
        GTEST_SKIP() << "Skipping test for warp size 32, array_size=" << GetParam().array_size \
                     << " and thread_block_size= " << GetParam().thread_block_size;            \
      }                                                                                        \
    }                                                                                          \
    InternalTestBody();                                                                        \
  }

STAMP_TEST_CASES(1);
STAMP_TEST_CASES(2);
STAMP_TEST_CASES(3);

INSTANTIATE_TEST_CASE_P(WarpSortAnyRegisters,
                        WarpSortAnyRegistersParameterizedQueueSize1,
                        ::testing::ValuesIn(std::vector<WarpSortAnyRegistersParameters>{
                          {.array_size = 10, .thread_block_size = 64},
                          {.array_size = 10, .thread_block_size = 32},
                          {.array_size = 64, .thread_block_size = 64}}));

INSTANTIATE_TEST_CASE_P(WarpSortAnyRegisters,
                        WarpSortAnyRegistersParameterizedQueueSize2,
                        ::testing::ValuesIn(std::vector<WarpSortAnyRegistersParameters>{
                          {.array_size = 10, .thread_block_size = 64},
                          {.array_size = 10, .thread_block_size = 32},
                          {.array_size = 64, .thread_block_size = 64},
                          {.array_size = 65, .thread_block_size = 64},
                          {.array_size = 128, .thread_block_size = 64}}));

INSTANTIATE_TEST_CASE_P(WarpSortAnyRegisters,
                        WarpSortAnyRegistersParameterizedQueueSize3,
                        ::testing::ValuesIn(std::vector<WarpSortAnyRegistersParameters>{
                          {.array_size = 10, .thread_block_size = 64},
                          {.array_size = 10, .thread_block_size = 32},
                          {.array_size = 64, .thread_block_size = 64},
                          {.array_size = 65, .thread_block_size = 64},
                          {.array_size = 128, .thread_block_size = 64},
                          {.array_size = 129, .thread_block_size = 64},
                          {.array_size = 150, .thread_block_size = 64},
                          {.array_size = 192, .thread_block_size = 64},
                        }));

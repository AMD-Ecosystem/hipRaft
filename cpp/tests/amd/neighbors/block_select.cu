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
__global__ void entry_point(float* keys, int32_t* values, size_t N, int k)
{
  __shared__ float s_keys[NumWarpQ * (ThreadsPerBlock / raft::warp_size())];
  __shared__ int32_t s_values[NumWarpQ * (ThreadsPerBlock / raft::warp_size())];
  constexpr bool Dir = true;
  using Comparator   = raft::neighbors::detail::faiss_select::Comparator<int32_t>;
  typedef raft::neighbors::detail::faiss_select::
    BlockSelect<float, int32_t, Dir, Comparator, NumWarpQ, NumThreadQ, ThreadsPerBlock>
      BlockSelectType;
  BlockSelectType heap(
    std::numeric_limits<float>::min(), std::numeric_limits<int32_t>::max(), s_keys, s_values, k);

  size_t index = threadIdx.x;
  int limit    = raft::Pow2<raft::WarpSize>::roundDown(N);
  for (; index < limit; index += ThreadsPerBlock) {
    heap.add(keys[index], values[index]);
  }
  if (index < N) { heap.addThreadQ(keys[index], values[index]); }

  heap.reduce();

  for (int i = threadIdx.x; i < k; i += ThreadsPerBlock) {
    keys[blockIdx.x * k + i]   = s_keys[i];
    values[blockIdx.x * k + i] = s_values[i];
  }
}

struct BlockSelectParameters {
  size_t array_size;
  int k;
};

class BlockSelectParameterized : public ::testing::TestWithParam<BlockSelectParameters> {
 protected:
  template <int NumWarpQ, int NumThreadQ, int ThreadsPerBlock>
  void InternalTestBody()
  {
    BlockSelectParameters const& parameters = GetParam();

    std::vector<float> h_keys(parameters.array_size);
    std::vector<int32_t> h_values(parameters.array_size);

    // Generate a monotonically increasing sequence
    // h_keys   = [0, 1, 2 ... N]
    // h_values = [0, 1, 2 ... N]
    std::iota(std::begin(h_keys), std::end(h_keys), 0);
    std::iota(std::begin(h_values), std::end(h_values), 0);

    rmm::device_uvector<float> d_keys(parameters.array_size, rmm::cuda_stream_default);
    rmm::device_uvector<int32_t> d_values(parameters.array_size, rmm::cuda_stream_default);

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
      EXPECT_FLOAT_EQ(h_keys[index], parameters.array_size - index - 1);
      EXPECT_EQ(h_values[index], parameters.array_size - index - 1);
    }
  }
};

class BlockSelectParameterizedTPB64 : public BlockSelectParameterized {
 protected:
  static constexpr int ThreadsPerBlock = 128;
};

TEST_P(BlockSelectParameterizedTPB64, ParameterCombination1)
{
  constexpr int NumThreadQ = 8;
  constexpr int NumWarpQ   = 1024;
  InternalTestBody<NumWarpQ, NumThreadQ, ThreadsPerBlock>();
}

INSTANTIATE_TEST_CASE_P(BlockSelectTests,
                        BlockSelectParameterizedTPB64,
                        ::testing::ValuesIn(std::vector<BlockSelectParameters>{
                          {.array_size = 8000, .k = 3},
                        }));

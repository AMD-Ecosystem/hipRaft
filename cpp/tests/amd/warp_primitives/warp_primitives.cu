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

#include <raft/core/cudart_utils.hpp>
#include <raft/core/device_container_policy.hpp>
#include <raft/core/device_mdarray.hpp>
#include <raft/core/operators.hpp>
#include <raft/cuda_runtime.h>
#include <raft/util/cuda_dev_essentials.cuh>
#include <raft/util/cuda_rt_essentials.hpp>
#include <raft/util/cudart_utils.hpp>
#include <raft/util/warp_primitives.cuh>

#include <rmm/cuda_stream_view.hpp>

#include <gtest/gtest.h>

#include <cstdint>

/**
 * @brief A simple kernel to warp_highest_active_lane
 *
 * @param warp_lane_data Pointer to store the data processed by each warp lane. Length is assumed to
 * be the size of a wavefront.
 */
__global__ void kernel(uint8_t* warp_lane_data, int32_t* output_index)
{
  auto lane_id          = raft::laneId();
  bool lane_flag_is_set = warp_lane_data[lane_id] != 0;
  *output_index         = raft::warp_highest_active_lane(lane_flag_is_set);
}

TEST(WarpPrimitives, WarpHighestActiveLane)
{
  auto const wavefront_size = raft::host_warp_size(0);

  std::vector<uint8_t> h_warp_lane_data(wavefront_size, 0);
  raft::device_uvector<uint8_t> d_warp_lane_data(wavefront_size, rmm::cuda_stream_default);
  raft::device_uvector<int32_t> d_output_index(1, rmm::cuda_stream_default);

  int32_t h_output_index{};
  {
    // Reset h_warp_lane_data to all zeros
    std::fill(h_warp_lane_data.begin(), h_warp_lane_data.end(), 0);
    // Set lane 5 and lane 10 to active
    h_warp_lane_data[5]  = 1;
    h_warp_lane_data[10] = 1;
    RAFT_CUDA_TRY(cudaMemcpy(d_warp_lane_data.data(),
                             h_warp_lane_data.data(),
                             wavefront_size * sizeof(uint8_t),
                             cudaMemcpyHostToDevice));
    kernel<<<1, wavefront_size>>>(d_warp_lane_data.data(), d_output_index.data());
    RAFT_CUDA_TRY(cudaDeviceSynchronize());
    RAFT_CUDA_TRY(
      cudaMemcpy(&h_output_index, d_output_index.data(), sizeof(int32_t), cudaMemcpyDeviceToHost));
    EXPECT_EQ(h_output_index, 10);
  }
  {
    // Reset h_warp_lane_data to all zeros
    std::fill(h_warp_lane_data.begin(), h_warp_lane_data.end(), 0);
    // Intentionally leave all lanes inactive
    RAFT_CUDA_TRY(cudaMemcpy(d_warp_lane_data.data(),
                             h_warp_lane_data.data(),
                             wavefront_size * sizeof(uint8_t),
                             cudaMemcpyHostToDevice));
    kernel<<<1, wavefront_size>>>(d_warp_lane_data.data(), d_output_index.data());
    RAFT_CUDA_TRY(cudaDeviceSynchronize());
    RAFT_CUDA_TRY(
      cudaMemcpy(&h_output_index, d_output_index.data(), sizeof(int32_t), cudaMemcpyDeviceToHost));
    // Since no lanes are active, expect -1
    EXPECT_EQ(h_output_index, -1);
  }
  {
    // Set all lanes to active
    std::fill(h_warp_lane_data.begin(), h_warp_lane_data.end(), 1);
    RAFT_CUDA_TRY(cudaMemcpy(d_warp_lane_data.data(),
                             h_warp_lane_data.data(),
                             wavefront_size * sizeof(uint8_t),
                             cudaMemcpyHostToDevice));
    kernel<<<1, wavefront_size>>>(d_warp_lane_data.data(), d_output_index.data());
    RAFT_CUDA_TRY(cudaDeviceSynchronize());
    RAFT_CUDA_TRY(
      cudaMemcpy(&h_output_index, d_output_index.data(), sizeof(int32_t), cudaMemcpyDeviceToHost));
    // Since the highest lane index is wavefront_size - 1
    EXPECT_EQ(h_output_index, wavefront_size - 1);
  }
}

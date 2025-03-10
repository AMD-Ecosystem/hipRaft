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

#include <raft/comms/std_comms.hpp>
#include <raft/core/comms.hpp>
#include <raft/core/device_mdarray.hpp>
#include <raft/core/device_setter.hpp>
#include <raft/core/host_mdarray.hpp>
#include <raft/core/resource/comms.hpp>
#include <raft/core/resource/cuda_stream_pool.hpp>

#include <rmm/cuda_device.hpp>
#include <rmm/cuda_stream.hpp>
#include <rmm/device_uvector.hpp>

#include <thrust/execution_policy.h>
#include <thrust/sequence.h>

#include <gtest/gtest.h>

#include <algorithm>
#include <numeric>
#include <vector>

/*
 * The tests ensure that multiple GPUs can correctly:
 * - Share and aggregate data
 * - Broadcast values from a source GPU to others
 * - Reduce distributed values to a single GPU
 * - Distribute (scatter) results back to GPUs
 *
 * These tests help validate the correctness, reliability, and performance aspects of
 * multi-GPU communication primitives in a RAFT + NCCL environment.
 */
class CommunicationsTest : public ::testing::Test {
  /**
   * @brief Initializes test resources before each test.
   *
   * This method:
   * - Obtains the number of available CUDA devices.
   * - Creates NCCL communicators for each device (via `ncclCommInitAll`).
   * - Creates RAFT resource handles and associates each with a communicator and a CUDA stream.
   */
  void SetUp() override
  {
    m_devices.resize(rmm::get_num_cuda_devices());
    std::iota(m_devices.begin(), m_devices.end(), 0);

    // Setup m_communicators per device
    m_communicators.resize(m_devices.size());
    EXPECT_EQ(ncclCommInitAll(m_communicators.data(), m_devices.size(), m_devices.data()),
              ncclResult_t::ncclSuccess);

    // Setup raft resource handle per device
    m_handles.resize(m_devices.size());
    for_each_device([&](int device_id) {
      auto& stream = m_streams.emplace_back();
      raft::resource::set_cuda_stream(m_handles[device_id], stream.view());
      raft::comms::build_comms_nccl_only(
        &m_handles[device_id], m_communicators[device_id], m_devices.size(), device_id);

      // Additional check to verify mapping of device<->communicator
      int queried_device{-1};
      EXPECT_EQ(ncclResult_t::ncclSuccess,
                ncclCommCuDevice(m_communicators[device_id], &queried_device));
      EXPECT_EQ(queried_device, device_id);
    });
  }

  /**
   * @brief Cleans up test resources after each test.
   *
   * Finalizes and destroys all NCCL communicators.
   */
  void TearDown() override
  {
    // Tear down the m_communicators
    EXPECT_NO_THROW(
      std::for_each(m_communicators.begin(), m_communicators.end(), [](ncclComm_t comm) {
        EXPECT_EQ(ncclResult_t::ncclSuccess, ncclCommFinalize(comm));
        EXPECT_EQ(ncclResult_t::ncclSuccess, ncclCommDestroy(comm));
      }));
  }

 protected:
  /**
   * @brief Executes a given function on each GPU device in a collection.
   *
   * @tparam F Functor type. Should be callable with a single integer argument.
   * @param[in] function  A function to call for each device, with `device_id` as input.
   */
  template <typename F>
  void for_each_device(F function)
  {
    std::for_each(m_devices.begin(), m_devices.end(), [&](int device_id) {
      raft::device_setter scoped_device(device_id);
      function(device_id);
    });
  }

 protected:
  std::vector<int> m_devices{};
  std::vector<ncclComm_t> m_communicators{};
  std::vector<rmm::cuda_stream> m_streams{};
  std::vector<raft::resources> m_handles{};
  std::vector<rmm::device_uvector<int>> m_send_device_vectors;
  std::vector<rmm::device_uvector<int>> m_recv_device_vectors;
  std::vector<rmm::device_scalar<int>> m_send_device_scalars;
  std::vector<rmm::device_scalar<int>> m_receive_device_scalars;
};

/**
 * @brief Tests NCCL Allreduce operation across multiple GPUs.
 *
 * This test:
 * - Initializes each device with a value of 1.
 * - Performs an allreduce (SUM) across all devices.
 * - Verifies that the result on each device is equal to the number of devices.
 */
TEST_F(CommunicationsTest, NCCLAllReduce)
{
  // Upload initial values to all m_devices
  for_each_device([&](int device_id) {
    auto& device_scalar                = m_send_device_scalars.emplace_back(m_streams[device_id]);
    static constexpr int INITIAL_VALUE = 1;
    m_send_device_scalars[device_id].set_value_async(INITIAL_VALUE, m_streams[device_id]);
    m_receive_device_scalars.emplace_back(m_streams[device_id]);
  });

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });

  // Start inter GPU comms
  ncclGroupStart();
  for_each_device([&](int device_id) {
    // Perform allreduce SUM of one integer across all GPUs
    auto const& communicator = raft::resource::get_comms(m_handles[device_id]);
    communicator.allreduce(m_send_device_scalars[device_id].data(),
                           m_receive_device_scalars[device_id].data(),
                           1,
                           raft::comms::op_t::SUM,
                           m_streams[device_id].view());
  });
  ncclGroupEnd();

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });

  // POST CONDITIONS
  // Verify each device received the sum of all initial values (devices * 1)
  for_each_device([&](int device_id) {
    EXPECT_EQ(m_receive_device_scalars[device_id].value(m_streams[device_id]), m_devices.size());
  });
}

/**
 * @brief Tests NCCL Broadcast operation.
 *
 * This test:
 * - Sets all devices to INITIAL_VALUE = 1.
 * - Overwrites the value on device 0 with BROADCAST_VALUE = 666.
 * - Broadcasts this value from device 0 to all other devices.
 * - Verifies that each device receives the broadcast value.
 */
TEST_F(CommunicationsTest, NCCLBroadCast)
{
  // Upload initial values to all m_devices
  for_each_device([&](int device_id) {
    auto& device_scalar                = m_send_device_scalars.emplace_back(m_streams[device_id]);
    static constexpr int INITIAL_VALUE = 1;
    m_send_device_scalars[device_id].set_value_async(INITIAL_VALUE, m_streams[device_id]);
  });
  static constexpr int BROADCAST_VALUE = 666;
  m_send_device_scalars[0].set_value_async(BROADCAST_VALUE, m_streams[0]);

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });

  // Start inter GPU comms
  ncclGroupStart();
  for_each_device([&](int device_id) {
    auto const& communicator = raft::resource::get_comms(m_handles[device_id]);
    communicator.bcast(m_send_device_scalars[device_id].data(), 1, 0, m_streams[device_id].view());
  });
  ncclGroupEnd();

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });

  // POST CONDITIONS
  // Verify that all devices have the broadcast value
  for_each_device([&](int device_id) {
    auto host_value = m_send_device_scalars[device_id].value(m_streams[device_id].view());
    EXPECT_EQ(host_value, BROADCAST_VALUE);
  });
}

/**
 * @brief Tests NCCL Reduce operation.
 *
 * This test:
 * - Initializes each device with INITIAL_VALUE = 1.
 * - Reduces (SUM) all values to a target lane (last GPU device).
 * - Verifies that the target device receives the sum of all devices' values.
 */
TEST_F(CommunicationsTest, NCCLReduce)
{
  // Upload initial values to all m_devices
  for_each_device([&](int device_id) {
    auto& device_scalar                = m_send_device_scalars.emplace_back(m_streams[device_id]);
    static constexpr int INITIAL_VALUE = 1;
    m_send_device_scalars[device_id].set_value_async(INITIAL_VALUE, m_streams[device_id]);
    m_receive_device_scalars.emplace_back(m_streams[device_id]);
  });

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });
  auto const TARGET_LANE = rmm::get_num_cuda_devices() - 1;
  // Start inter GPU comms
  ncclGroupStart();
  for_each_device([&](int device_id) {
    auto const& communicator = raft::resource::get_comms(m_handles[device_id]);
    communicator.reduce(m_send_device_scalars[device_id].data(),
                        m_receive_device_scalars[device_id].data(),
                        1,
                        raft::comms::op_t::SUM,
                        TARGET_LANE,  // Destination is the last lane
                        m_streams[device_id].view());
  });
  ncclGroupEnd();

  // POST CONDITIONS
  // Synchronize and verify that the target lane has the sum of all initial values
  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });
  EXPECT_EQ(m_receive_device_scalars[TARGET_LANE].value(m_streams[TARGET_LANE]), m_devices.size());
}

/**
 * @brief Tests NCCL AllGather operation.
 *
 * This test:
 * - Each device sends a unique value equal to its device ID.
 * - Performs an allgather so that every device ends up with a vector of all device IDs.
 * - Verifies that each device has correctly gathered all IDs.
 */
TEST_F(CommunicationsTest, NCCLAllGather)
{
  // Upload initial values to all m_devices
  for_each_device([&](int device_id) {
    auto& device_vector =
      m_send_device_vectors.emplace_back(m_devices.size(), m_streams[device_id]);
    m_send_device_vectors[device_id].set_element(device_id, device_id, m_streams[device_id]);
    m_recv_device_vectors.emplace_back(m_devices.size(), m_streams[device_id]);
  });

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });
  auto const TARGET_LANE = rmm::get_num_cuda_devices() - 1;
  // Start inter GPU comms
  ncclGroupStart();
  for_each_device([&](int device_id) {
    auto const& communicator = raft::resource::get_comms(m_handles[device_id]);
    communicator.allgather(m_send_device_vectors[device_id].element_ptr(device_id),
                           m_recv_device_vectors[device_id].data(),
                           1,
                           m_streams[device_id].view());
  });
  ncclGroupEnd();

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });

  // POST CONDITIONS
  // Verify that each device received all device IDs in order
  for_each_device([&](int device_id) {
    auto const& device_vector = m_recv_device_vectors[device_id];
    for (int index = 0; index < device_vector.size(); ++index) {
      EXPECT_EQ(device_vector.element(index, m_streams[index]), index);
    }
  });
}

/**
 * @brief Tests NCCL ReduceScatter operation.
 *
 * This test:
 * - Initializes a vector of ascending values on each device.
 * - Performs a reduce-scatter (SUM), distributing aggregated partial results to each device.
 * - Verifies that each device's portion of the result matches the expected reduced value.
 */
TEST_F(CommunicationsTest, NCCLReduceScatter)
{
  // Upload initial values to all m_devices
  for_each_device([&](int device_id) {
    auto& device_vector =
      m_send_device_vectors.emplace_back(m_devices.size(), m_streams[device_id]);
    // Fill with a sequence: 0,1,2,... for verification
    thrust::sequence(thrust::__THRUST_DEVICE_SYSTEM_NAMESPACE::par.on(m_streams[device_id].view()),
                     device_vector.begin(),
                     device_vector.end());
    m_recv_device_vectors.emplace_back(device_vector.size(), m_streams[device_id]);
  });

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });
  auto const TARGET_LANE = rmm::get_num_cuda_devices() - 1;
  // Start inter GPU comms
  // Perform reduce-scatter:
  // SUM all corresponding elements across devices, then scatter the results so that
  // each device gets one reduced element.
  ncclGroupStart();
  for_each_device([&](int device_id) {
    auto const& communicator = raft::resource::get_comms(m_handles[device_id]);
    communicator.reducescatter(m_send_device_vectors[device_id].data(),
                               m_recv_device_vectors[device_id].element_ptr(device_id),
                               1,
                               raft::comms::op_t::SUM,
                               m_streams[device_id].view());
  });
  ncclGroupEnd();

  for_each_device([&](int device_id) { m_streams[device_id].synchronize(); });

  // POST CONDITIONS
  // Verify that each device received the sum of the "device_id"-th elements from all devices
  for_each_device([&](int device_id) {
    auto const& device_vector = m_recv_device_vectors[device_id];
    // The expected value is (device_id * number_of_devices) because each device contributes
    // the same position index as its value in that position.
    EXPECT_EQ(device_vector.element(device_id, m_streams[device_id]), device_id * m_devices.size());
  });
}

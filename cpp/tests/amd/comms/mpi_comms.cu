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

/**
 * @file mpi_comms.cu
 * @brief Demonstration and tests of multi-GPU communications using MPI and RAFT.
 *
 * This file sets up MPI-based multi-GPU communication tests that leverage RAFT's MPI communicators.
 * Each test uses RAFT's distributed communication primitives (allreduce, broadcast, reduce,
 * allgather, reducescatter) to verify correctness and integration with an MPI runtime environment.
 *
 * Requirements:
 * - MPI runtime (OpenMPI or equivalent)
 * - Multiple GPUs accessible on the system
 * - RAFT, RMM, Thrust, and GTest frameworks properly installed and configured
 *
 * Usage:
 * Tests are typically launched via `mpirun` or `srun`. For example:
 * @code
 * mpirun -np <NUM_PROCS> ./mpi_comms_test_executable
 * @endcode
 */

#include <raft/comms/mpi_comms.hpp>
#include <raft/core/comms.hpp>
#include <raft/core/resource/comms.hpp>
#include <raft/core/resource/cuda_stream.hpp>

#include <rmm/cuda_device.hpp>
#include <rmm/cuda_stream.hpp>
#include <rmm/device_uvector.hpp>

#include <thrust/execution_policy.h>
#include <thrust/sequence.h>

#include <gtest/gtest.h>
#include <mpi.h>

#include <cstdint>

/**
 * @class MPIEnvironment
 * @brief A global testing environment for initializing and finalizing MPI.
 *
 * This class ensures MPI_Init and MPI_Finalize are called exactly once for all tests.
 * Using a global environment set via ::testing::AddGlobalTestEnvironment ensures
 * that MPI is ready before any tests run and is properly cleaned up after all tests complete.
 */
class MPIEnvironment : public ::testing::Environment {
 public:
  MPIEnvironment(int argc, char* argv[]) { EXPECT_EQ(0, MPI_Init(&argc, &argv)); }
  ~MPIEnvironment() override { EXPECT_EQ(0, MPI_Finalize()); }
};

/**
 * @class MPICommunicationsTest
 * @brief Test fixture for MPI-based multi-GPU communication tests.
 *
 * This class:
 * - Initializes and configures the RAFT handle with MPI-based communicators.
 * - Sets the CUDA device based on MPI rank.
 * - Tests various distributed communication operations on multiple GPUs.
 *
 * Each test uses the RAFT `comms_t` communicator and RAFT resources to perform collective
 * operations and verify their correctness.
 */
class MPICommunicationsTest : public ::testing::Test {
  /**
   * @brief Initializes the test fixture before each test.
   *
   * This method:
   * - Determines the calling MPI process's rank (m_deviceID) and the world size (m_worldSize).
   * - Sets the current CUDA device based on the rank.
   * - Initializes MPI communicators within RAFT for multi-GPU operations.
   */
  void SetUp() override
  {
    EXPECT_EQ(0, MPI_Comm_rank(MPI_COMM_WORLD, &m_deviceID));
    EXPECT_EQ(0, MPI_Comm_size(MPI_COMM_WORLD, &m_worldSize));
    // Set the device based on MPI rank. The way mpirun is setup, it will launch the same number of
    // processes as there are GPU's on the host system.
    EXPECT_EQ(hipError_t::hipSuccess, hipSetDevice(m_deviceID)) << m_deviceID;
    EXPECT_NO_THROW(raft::comms::initialize_mpi_comms(&m_handle, MPI_COMM_WORLD));
  }

 protected:
  raft::resources m_handle{};
  int32_t m_deviceID{-1};
  int32_t m_worldSize{-1};
};

/**
 * @test Verifies the MPI-based allreduce operation.
 *
 * This test:
 * - Initializes each GPU with a value of 1.
 * - Performs an allreduce (SUM) across all processes.
 * - Verifies that the resulting value is equal to the world size (since each GPU contributed '1').
 */
TEST_F(MPICommunicationsTest, AllReduce)
{
  rmm::device_scalar<int> send_device_scalar(raft::resource::get_cuda_stream(m_handle));
  rmm::device_scalar<int> receive_device_scalar(raft::resource::get_cuda_stream(m_handle));
  static constexpr int INITIAL_VALUE = 1;
  send_device_scalar.set_value_async(INITIAL_VALUE, raft::resource::get_cuda_stream(m_handle));
  raft::resource::sync_stream(m_handle);

  auto const& communicator = raft::resource::get_comms(m_handle);

  communicator.allreduce(send_device_scalar.data(),
                         receive_device_scalar.data(),
                         1,
                         raft::comms::op_t::SUM,
                         raft::resource::get_cuda_stream(m_handle));
  raft::resource::sync_stream(m_handle);
  EXPECT_EQ(receive_device_scalar.value(raft::resource::get_cuda_stream(m_handle)), m_worldSize);
}

/**
 * @test Verifies the MPI-based broadcast operation.
 *
 * This test:
 * - Initializes a scalar to 1 on all ranks.
 * - The root rank (0) overwrites its value with a broadcast value (666).
 * - Broadcasts this value to all ranks.
 * - Verifies that all ranks have received the broadcast value (666).
 */
TEST_F(MPICommunicationsTest, BroadCast)
{
  static constexpr int INITIAL_VALUE   = 1;
  static constexpr int BROADCAST_VALUE = 666;  // Only set for rank == 0
  rmm::device_scalar<int> send_device_scalar(raft::resource::get_cuda_stream(m_handle));
  send_device_scalar.set_value_async(INITIAL_VALUE, raft::resource::get_cuda_stream(m_handle));
  raft::resource::sync_stream(m_handle);

  raft::comms::comms_t const& communicator = raft::resource::get_comms(m_handle);
  if (m_deviceID == 0) {
    send_device_scalar.set_value_async(BROADCAST_VALUE, raft::resource::get_cuda_stream(m_handle));
    raft::resource::sync_stream(m_handle);
    EXPECT_EQ(send_device_scalar.value(raft::resource::get_cuda_stream(m_handle)), BROADCAST_VALUE);
  }
  communicator.bcast(send_device_scalar.data(), 1, 0, raft::resource::get_cuda_stream(m_handle));
  raft::resource::sync_stream(m_handle);
  EXPECT_EQ(send_device_scalar.value(raft::resource::get_cuda_stream(m_handle)), BROADCAST_VALUE);
}

/**
 * @test Verifies the MPI-based reduce operation.
 *
 * This test:
 * - Initializes a scalar with the value 1 on every rank.
 * - Reduces all values into the root rank (0) using SUM.
 * - The root rank verifies that it received the sum equal to the world size.
 * - Non-root ranks send only and do not receive the output buffer.
 */
TEST_F(MPICommunicationsTest, Reduce)
{
  rmm::device_scalar<int> send_device_scalar(raft::resource::get_cuda_stream(m_handle));
  rmm::device_scalar<int> receive_device_scalar(raft::resource::get_cuda_stream(m_handle));
  static constexpr int INITIAL_VALUE = 1;
  send_device_scalar.set_value_async(INITIAL_VALUE, raft::resource::get_cuda_stream(m_handle));
  raft::resource::sync_stream(m_handle);

  raft::comms::comms_t const& communicator = raft::resource::get_comms(m_handle);
  if (m_deviceID != 0) {
    communicator.reduce(send_device_scalar.data(),
                        static_cast<int*>(nullptr),
                        1,
                        raft::comms::op_t::SUM,
                        0,
                        raft::resource::get_cuda_stream(m_handle));
  } else {
    communicator.reduce(send_device_scalar.data(),
                        receive_device_scalar.data(),
                        1,
                        raft::comms::op_t::SUM,
                        0,
                        raft::resource::get_cuda_stream(m_handle));
  }
  raft::resource::sync_stream(m_handle);
  if (m_deviceID == 0) {
    EXPECT_EQ(receive_device_scalar.value(raft::resource::get_cuda_stream(m_handle)), m_worldSize);
  }
}

/**
 * @test Verifies the MPI-based allgather operation.
 *
 * This test:
 * - Each rank sets its send_vector element corresponding to its rank index to its own rank ID.
 * - Allgather collects these values from all ranks into `receive_vector` on each rank.
 * - After the allgather, each rank’s `receive_vector` should contain a sequence of all rank IDs.
 */
TEST_F(MPICommunicationsTest, AllGather)
{
  auto stream_view = raft::resource::get_cuda_stream(m_handle);
  rmm::device_uvector<int> send_vector(m_worldSize, stream_view);
  rmm::device_uvector<int> receive_vector(m_worldSize, stream_view);

  send_vector.set_element(m_deviceID, m_deviceID, stream_view);
  raft::resource::sync_stream(m_handle);

  raft::comms::comms_t const& communicator = raft::resource::get_comms(m_handle);
  communicator.allgather(
    send_vector.element_ptr(m_deviceID), receive_vector.data(), 1, stream_view);
  raft::resource::sync_stream(m_handle);
  for (int index = 0; index < receive_vector.size(); ++index) {
    EXPECT_EQ(receive_vector.element(index, stream_view), index);
  }
}

/**
 * @test Verifies the MPI-based reducescatter operation.
 *
 * This test:
 * - Uses `thrust::sequence` to fill `send_vector` with values [0, 1, 2, ...].
 * - Performs a reduce-scatter operation (SUM), so that each rank receives one reduced element.
 * - The expected result is that each rank receives the sum of the values at its index position from
 * all ranks.
 * - Given a sequence [0, 1, 2, ...], the sum at index `rank_id` across all ranks is `rank_id *
 * world_size`.
 */
TEST_F(MPICommunicationsTest, ReduceScatter)
{
  auto stream_view = raft::resource::get_cuda_stream(m_handle);
  rmm::device_uvector<int> send_vector(m_worldSize, stream_view);
  rmm::device_uvector<int> receive_vector(m_worldSize, stream_view);

  thrust::sequence(thrust::__THRUST_DEVICE_SYSTEM_NAMESPACE::par.on(stream_view),
                   send_vector.begin(),
                   send_vector.end());

  raft::resource::sync_stream(m_handle);

  raft::comms::comms_t const& communicator = raft::resource::get_comms(m_handle);
  communicator.reducescatter(send_vector.data(),
                             receive_vector.element_ptr(m_deviceID),
                             1,
                             raft::comms::op_t::SUM,
                             stream_view);

  EXPECT_EQ(receive_vector.element(m_deviceID, stream_view), m_deviceID * m_worldSize);
}

/**
 * @brief Main entry point for the MPI-based communications test binary.
 *
 * Initializes GTest, sets up the MPI environment, and runs all tests.
 *
 * @param[in] argc Number of command-line arguments.
 * @param[in] argv Array of command-line arguments.
 * @return int Returns the exit status from GoogleTest (0 = success).
 */
int main(int argc, char* argv[])
{
  ::testing::InitGoogleTest(&argc, argv);
  ::testing::AddGlobalTestEnvironment(new MPIEnvironment(argc, argv));
  return RUN_ALL_TESTS();
}

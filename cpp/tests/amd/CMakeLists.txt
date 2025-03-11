# MIT License
#
# Copyright (c) 2025 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if(BUILD_TESTS)
  ConfigureTest(
    NAME RUNTIME_RANDOM_TEST PATH runtime_random/rmat_rectangular_generator.cu LIB
    EXPLICIT_INSTANTIATE_ONLY
  )
  ConfigureTest(
    NAME NEIGHBORS_UTILS_TEST PATH neighbors/merge_network_warp.cu neighbors/faiss_select.cu
    neighbors/block_select.cu
  )

  ConfigureTest(
        NAME SRC_LINALG_TEST PATH src_linalg/coalasced_reduction.cu LIB EXPLICIT_INSTANTIATE_ONLY
  )

  if(TARGET ucx::ucp
     AND TARGET ucx::ucs
     AND DEFINED MPI_FOUND
  )
    # raft_distributed tests
    ConfigureTest(NAME STD_COMMS_TEST PATH comms/std_comms.cu)
    target_link_libraries(STD_COMMS_TEST PRIVATE raft_distributed)
    # Set test properties to indicate that this test uses all GPUs and should lock the resources.
    set_tests_properties(STD_COMMS_TEST PROPERTIES RESOURCE_LOCK gpus)

    add_executable(mpi_comms_test_executable comms/mpi_comms.cu)
    target_link_libraries(
      mpi_comms_test_executable PRIVATE raft raft::distributed ${MPI_LIBRARIES} GTest::gtest
    )
    # Add a test invocation that runs the MPI communications test using mpirun
    add_test(
      NAME MPI_COMMS_TEST_MPI_RUN
      COMMAND
        bash -c
        "${MPIEXEC_EXECUTABLE} --allow-run-as-root -np 1 $<TARGET_FILE:mpi_comms_test_executable>"
    )
  endif()

endif()

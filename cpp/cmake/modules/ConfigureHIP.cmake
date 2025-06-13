# MIT License
#
# Copyright (c) 2024-2025 Advanced Micro Devices, Inc.
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

if(DISABLE_DEPRECATION_WARNINGS)
  list(APPEND RAFT_CXX_FLAGS -Wno-deprecated-declarations -DRAFT_HIDE_DEPRECATION_WARNINGS)
  list(APPEND RAFT_GPU_FLAGS -Wno-deprecated-declarations -DRAFT_HIDE_DEPRECATION_WARNINGS)
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  # TODO:(HIP/AMD) We want to prune the following warning disable lists.
  list(APPEND CXX_WARNINGS_DISABLE_LIST -Wno-unused-result -Wno-unknown-pragmas
       -Wno-macro-redefined -Wno-inconsistent-missing-override
  )
  list(
    APPEND
    GPU_WARNINGS_DISABLE_LIST
    -Wno-unused-result
    -Wno-unknown-pragmas
    -Wno-macro-redefined
    -Wno-inconsistent-missing-override
    -Wno-reorder-ctor
    -Wno-unused-variable
    -Wno-unused-local-typedef
    -Wno-unused-but-set-variable
    -Wno-pass-failed
    -Wno-unused-lambda-capture
    -Wno-uninitialized
    -Wno-unsequenced
    -Wno-vla-cxx-extension
    -Wno-mismatched-tags
    -Wno-unused-private-field
  )
  list(APPEND RAFT_CXX_FLAGS -Wall -Werror ${CXX_WARNINGS_DISABLE_LIST})
  list(APPEND RAFT_GPU_FLAGS -Wall -Werror ${GPU_WARNINGS_DISABLE_LIST})
endif()

# TODO(HIP/AMD): port this if(CUDA_LOG_COMPILE_TIME) list(APPEND RAFT_GPU_FLAGS
# "--time=nvcc_compile_log.csv") endif()

list(APPEND RAFT_CXX_FLAGS "-fgpu-default-stream=per-thread")
list(APPEND RAFT_GPU_FLAGS "-fgpu-default-stream=per-thread")

if(CUDA_ENABLE_LINEINFO)
  # Option to enable line info in CUDA device compilation to allow introspection when profiling /
  # memchecking
  message(FATAL_ERROR "RAFT does not support line-number information for hip platform")
endif()

if(OpenMP_FOUND)
  list(APPEND RAFT_GPU_FLAGS ${OpenMP_CXX_FLAGS})
endif()

# Debug options
if(CMAKE_BUILD_TYPE MATCHES Debug)
  message(VERBOSE "RAFT: Building with debugging flags and optimizations off")
  # Disable optimizations and enable debug symbols with additional GDB specific metadata.
  list(APPEND RAFT_GPU_FLAGS -ggdb -O0)
endif()

# RelWithDebInfo options
if(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)
  message(VERBOSE "RAFT: Building with debugging flags")
  # Enable debug symbols with additional GDB specific metadata.
  list(APPEND RAFT_GPU_FLAGS -ggdb)
endif()

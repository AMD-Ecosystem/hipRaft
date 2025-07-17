# =============================================================================
# Copyright (c) 2023-2024, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.

# Modifications Copyright (c) 2025 Advanced Micro Devices, Inc. Permission is hereby granted, free
# of charge, to any person obtaining a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the following
# conditions: The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

cmake_minimum_required(VERSION 3.26.4 FATAL_ERROR)

# ------------- configure rapids-cmake --------------#
include(../cmake/thirdparty/fetch_rapids.cmake)
include(rapids-cmake)
include(rapids-cpm)
include(rapids-export)
include(rapids-find)

# ------------- configure project --------------#

option(CUDA_BACKEND "Build for CUDA devices. Default configuration builds for AMD devices." OFF)

# workaround for rapids_cuda_init_architectures not working for arch detection with
# enable_language(CUDA)
set(lang_list "CXX")

if(CUDA_BACKEND)
  include(rapids-cuda)
  rapids_cuda_init_architectures(raft_cxx_examples)
  list(APPEND lang_list "CUDA")
else()
  include(rapids-hip)
  rapids_hip_init_architectures(raft_cxx_examples)
  list(APPEND lang_list "HIP")
endif()

project(raft_cxx_examples LANGUAGES ${lang_list})

# ------------- configure raft -----------------#

rapids_cpm_init()
include(../cmake/thirdparty/get_raft.cmake)

# -------------- compile tasks ----------------- #
function(add_raft_cxx_example TARGET_NAME SOURCE_FILE)
  if(NOT CUDA_BACKEND)
    set_source_files_properties(${SOURCE_FILE} PROPERTIES LANGUAGE HIP)
  endif()
  add_executable(${TARGET_NAME} ${SOURCE_FILE})
  target_link_libraries(${TARGET_NAME} PRIVATE raft::raft raft::compiled)
endfunction()

add_raft_cxx_example(MAKE_BLOBS_EXAMPLE src/make_blobs_example.cu)
add_raft_cxx_example(LINALG_EXAMPLE src/linalg_example.cu)

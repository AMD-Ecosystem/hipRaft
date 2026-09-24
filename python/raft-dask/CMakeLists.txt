# =============================================================================
# cmake-format: off
# SPDX-FileCopyrightText: Copyright (c) 2022-2025, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
# cmake-format: on
# =============================================================================

# cmake-format: off
# MIT License
#
# Modifications Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# cmake-format: on

# =============================================================================
cmake_minimum_required(VERSION 3.30.4 FATAL_ERROR)

include(../../cmake/rapids_config.cmake)
include(rapids-cpm)
include(rapids-cuda)
include(rapids-find)
rapids_cuda_init_architectures(raft-dask-python)

set(lang_list "CXX")
if(CUDA_BACKEND)
  list(APPEND lang_list "CUDA")
else()
  list(APPEND lang_list "HIP")
endif()

project(
  libraft-python
  VERSION "${RAPIDS_VERSION}"
  LANGUAGES ${lang_list}
)

rapids_cpm_init()
include(cmake/thirdparty/get_ucxx.cmake)

# why these components:
#
# * 'raft' = the headers, needed to link against libraft
# * 'distributed' = needed for NCCL
find_package(raft "${RAPIDS_VERSION}" REQUIRED COMPONENTS raft distributed)

include(rapids-cython-core)
rapids_cython_init()

add_subdirectory(raft_dask/common)
add_subdirectory(raft_dask/include_test)

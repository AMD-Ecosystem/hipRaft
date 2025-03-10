#=============================================================================
# Copyright (c) 2024, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#=============================================================================
# Modifications Copyright (c) 2025 Advanced Micro Devices, Inc.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
function(find_and_configure_ucxx)
    set(oneValueArgs VERSION FORK PINNED_TAG EXCLUDE_FROM_ALL)
    set(options UCXX_STATIC)
    cmake_parse_arguments(PKG "${options}" "${oneValueArgs}"
            "${multiValueArgs}" ${ARGN} )

    set(BUILD_UCXX_SHARED ON)
    if(PKG_UCXX_STATIC)
      set(BUILD_UCXX_SHARED OFF)
    endif()
    rapids_cpm_find(ucxx ${PKG_VERSION}
            GLOBAL_TARGETS         ucxx::ucxx ucxx::python
            BUILD_EXPORT_SET       raft-distributed-exports
            INSTALL_EXPORT_SET     raft-distributed-exports
            PATCH_COMMAND          git checkout -- . && git apply ${CMAKE_CURRENT_LIST_DIR}/ucxx.diff # TODO: (HIP/AMD) Remove this patch once upstream fixes issues related to lambda captures
            CPM_ARGS
            GIT_REPOSITORY         https://github.com/${PKG_FORK}/ucxx.git
            GIT_TAG                ${PKG_PINNED_TAG}
            SOURCE_SUBDIR          cpp
            EXCLUDE_FROM_ALL       ${PKG_EXCLUDE_FROM_ALL}
            OPTIONS
              "BUILD_TESTS OFF"
              "BUILD_BENCH OFF"
              "UCXX_ENABLE_PYTHON ON"
              "UCXX_ENABLE_RMM OFF" # TODO: (HIP/AMD) This causes a compilation error in libhipcxx. "error: unknown pragma ignored" define _LIBCUDACXX_DISABLE_EXEC_CHECK _Pragma("nv_exec_check_disable")
              "BUILD_SHARED_LIBS ${BUILD_UCXX_SHARED}"
        )

endfunction()

# Change pinned tag here to test a commit in CI
# To use a different ucxx locally, set the CMake variable
# CPM_ucxx_SOURCE=/path/to/local/ucxx
find_and_configure_ucxx(VERSION  0.42
        FORK             rapidsai
        PINNED_TAG       branch-0.42
        EXCLUDE_FROM_ALL YES
        UCXX_STATIC      ${RAFT_DASK_UCXX_STATIC}
    )

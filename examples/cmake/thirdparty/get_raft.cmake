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
#
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

set(RAFT_VERSION "1.0.0")
set(RAFT_FORK "ROCm-DS")
set(RAFT_PINNED_TAG "release/rocmds-26.03")
# When PINNED_TAG above doesn't match the default branch,
# force local raft clone in build directory
# even if it's already installed.
set(RAFT_CLONE_ON_PIN ON)

function(find_and_configure_raft)
    set(oneValueArgs VERSION FORK PINNED_TAG COMPILE_LIBRARY ENABLE_MNMG_DEPENDENCIES CLONE_ON_PIN)
    cmake_parse_arguments(PKG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT CPM_raft_SOURCE AND PKG_CLONE_ON_PIN AND NOT PKG_PINNED_TAG STREQUAL "release/rocmds-26.03")
        message(STATUS "RAFT pinned tag found: ${PKG_PINNED_TAG}. Cloning raft locally.")
        set(CPM_DOWNLOAD_raft ON)
    endif()

    set(RAFT_COMPONENTS "")
    if(PKG_COMPILE_LIBRARY)
        string(APPEND RAFT_COMPONENTS " compiled")
    endif()

    if(PKG_ENABLE_MNMG_DEPENDENCIES)
        string(APPEND RAFT_COMPONENTS " distributed")
    endif()

    #-----------------------------------------------------
    # Invoke CPM find_package()
    #-----------------------------------------------------
    rapids_cpm_find(raft ${PKG_VERSION}
            GLOBAL_TARGETS      raft::raft
            BUILD_EXPORT_SET    raft-template-exports
            INSTALL_EXPORT_SET  raft-template-exports
            COMPONENTS          ${RAFT_COMPONENTS}
            CPM_ARGS
            GIT_REPOSITORY https://github.com/${PKG_FORK}/hipRaft.git
            GIT_TAG        ${PKG_PINNED_TAG}
            SOURCE_SUBDIR  cpp
            OPTIONS
                "BUILD_TESTS OFF"
                "BUILD_PRIMS_BENCH OFF"
                "BUILD_ANN_BENCH OFF"
                "RAFT_COMPILE_LIBRARY ${PKG_COMPILE_LIBRARY}"
            )
endfunction()

# Change pinned tag here to test a commit in CI
# To use a different RAFT locally, set the CMake variable
# CPM_raft_SOURCE=/path/to/local/raft
find_and_configure_raft(VERSION  ${RAFT_VERSION}
        FORK                     ${RAFT_FORK}
        PINNED_TAG               ${RAFT_PINNED_TAG}
        COMPILE_LIBRARY          ON
        ENABLE_MNMG_DEPENDENCIES OFF
        CLONE_ON_PIN             ${RAFT_CLONE_ON_PIN}
)

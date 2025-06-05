# =============================================================================
# Copyright (c) 2018-2024, NVIDIA CORPORATION.
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
# =============================================================================

# Modifications Copyright (c) 2024-2025 Advanced Micro Devices, Inc. Permission is hereby granted,
# free of charge, to any person obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
# Software, and to permit persons to whom the Software is furnished to do so, subject to the
# following conditions: The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
# WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.

file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" _rapids_version)
if(_rapids_version MATCHES [[^([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9])]])
  set(RAPIDS_VERSION_MAJOR "${CMAKE_MATCH_1}")
  set(RAPIDS_VERSION_MINOR "${CMAKE_MATCH_2}")
  set(RAPIDS_VERSION_PATCH "${CMAKE_MATCH_3}")
  set(RAPIDS_VERSION_MAJOR_MINOR "${RAPIDS_VERSION_MAJOR}.${RAPIDS_VERSION_MINOR}")
  set(RAPIDS_VERSION "${RAPIDS_VERSION_MAJOR}.${RAPIDS_VERSION_MINOR}.${RAPIDS_VERSION_PATCH}")
else()
  string(REPLACE "\n" "\n  " _rapids_version_formatted "  ${_rapids_version}")
  message(
    FATAL_ERROR
      "Could not determine RAPIDS version. Contents of VERSION file:\n${_rapids_version_formatted}"
  )
endif()

set(RAPIDS_CMAKE_MODULE_PATH
    $ENV{RAPIDS_CMAKE_MODULE_PATH}
    CACHE FILEPATH "Announce that ROCmDS-CMake is available via the provided module path."
)
if(NOT "${RAPIDS_CMAKE_MODULE_PATH}" STREQUAL "")
  # If RAPIDS_CMAKE_MODULE_PATH is set we want to use ROCmDS-CMake that's available in that path.
  list(APPEND CMAKE_MODULE_PATH "${RAPIDS_CMAKE_MODULE_PATH}")
  include(rapids-cmake)
  return()
endif()

if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/RAFT_RAPIDS-${RAPIDS_VERSION_MAJOR_MINOR}.cmake")
  # ################################################################################################
  # The following overrides are to be removed once the GA target ROCmDS-cmake branch is made public.
  # cmake-format: off
  # For now we need to set the following environment variables so that downstream CMake scripts all pull from a consistent location.
  #   - RAPIDS_CMAKE_SCRIPT_BRANCH: Which branch of the public ROCmDS-cmake git repository to pull the entrypoint RAPIDS.cmake script from.
  #   - RAPIDS_CMAKE_URL:           URL to the internal ROCmDS-cmake git repository
  #   - RAPIDS_CMAKE_BRANCH:        ROCmDS-cmake branch to use.
  # cmake-format: on
  set(ENV{RAPIDS_CMAKE_SCRIPT_BRANCH} release/1.0.x)
  if(NOT DEFINED ENV{RAPIDS_CMAKE_BRANCH})
    set(BRANCH "amd-integration/2.0.x")
    message(STATUS "Setting \"RAPIDS_CMAKE_BRANCH\" environment variable to ${BRANCH}")
    set(ENV{RAPIDS_CMAKE_BRANCH} ${BRANCH})
  endif()
  if(NOT DEFINED ENV{RAPIDS_CMAKE_URL})
    if(NOT DEFINED ENV{GITHUB_PASS})
      message(
        FATAL_ERROR "Please set the \"GITHUB_PASS\" environment variable with your Github API key"
      )
    endif()
    message(STATUS "Setting the \"RAPIDS_CMAKE_URL\" environment variable")
    set(ENV{RAPIDS_CMAKE_URL} https://$ENV{GITHUB_PASS}@github.com/AMD-AI/ROCmDS-cmake)
  endif()
  # ################################################################################################
  if(DEFINED ENV{RAPIDS_CMAKE_SCRIPT_BRANCH})
    set(RAPIDS_CMAKE_SCRIPT_BRANCH "$ENV{RAPIDS_CMAKE_SCRIPT_BRANCH}")
  else()
    set(RAPIDS_CMAKE_SCRIPT_BRANCH release/1.0.x)
  endif()
  set(URL
      "https://raw.githubusercontent.com/ROCm-DS/ROCmDS-CMake/${RAPIDS_CMAKE_SCRIPT_BRANCH}/RAPIDS.cmake"
  )
  file(DOWNLOAD ${URL} "${CMAKE_CURRENT_BINARY_DIR}/RAFT_RAPIDS-${RAPIDS_VERSION_MAJOR_MINOR}.cmake"
       STATUS DOWNLOAD_STATUS
  )
  list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
  list(GET DOWNLOAD_STATUS 1 ERROR_MESSAGE)

  if(${STATUS_CODE} EQUAL 0)
    message(STATUS "Downloaded 'RAFT_RAPIDS-${RAPIDS_VERSION_MAJOR_MINOR}.cmake' successfully!")
  else()
    file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/RAFT_RAPIDS-${RAPIDS_VERSION_MAJOR_MINOR}.cmake)
    message(
      FATAL_ERROR
        "Failed to download RAFT_RAPIDS-${RAPIDS_VERSION_MAJOR_MINOR}.cmake'. URL: ${URL}, Reason: ${ERROR_MESSAGE}"
    )
    message(
      FATAL_ERROR
        "Failed to download 'RAFT_RAPIDS-${RAPIDS_VERSION_MAJOR_MINOR}.cmake'. Reason: ${ERROR_MESSAGE}"
    )
  endif()
endif()
include("${CMAKE_CURRENT_BINARY_DIR}/RAFT_RAPIDS-${RAPIDS_VERSION_MAJOR_MINOR}.cmake")

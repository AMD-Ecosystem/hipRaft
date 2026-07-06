# =============================================================================
# cmake-format: off
# SPDX-FileCopyrightText: Copyright (c) 2018-2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
# cmake-format: on
# =============================================================================

# MIT License
#
# Modifications Copyright (C) 2024-2026 Advanced Micro Devices, Inc. All rights reserved.
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

# cmake-lint: disable=W0106

file(READ "${CMAKE_CURRENT_LIST_DIR}/../VERSION" _rapids_version)
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
  list(APPEND CMAKE_MODULE_PATH "${RAPIDS_CMAKE_MODULE_PATH}")
  # NOTE(HIP/AMD): needed to set rapids-cmake-dir variable
  include(rapids-cmake)
else()
  include("${CMAKE_CURRENT_LIST_DIR}/RAPIDS.cmake")
endif()

# Read UCXX version and branch files
file(READ "${CMAKE_CURRENT_LIST_DIR}/../UCXX_VERSION" _ucxx_version)
if(_ucxx_version MATCHES [[^([0-9]+)\.([0-9]+)\.([0-9]+)]])
  set(UCXX_VERSION_MAJOR "${CMAKE_MATCH_1}")
  set(UCXX_VERSION_MINOR "${CMAKE_MATCH_2}")
  set(UCXX_VERSION_PATCH "${CMAKE_MATCH_3}")
  set(UCXX_VERSION_MAJOR_MINOR "${UCXX_VERSION_MAJOR}.${UCXX_VERSION_MINOR}")
  set(UCXX_VERSION "${UCXX_VERSION_MAJOR}.${UCXX_VERSION_MINOR}.${UCXX_VERSION_PATCH}")
else()
  string(REPLACE "\n" "\n  " _ucxx_version_formatted "  ${_ucxx_version}")
  message(
    FATAL_ERROR
      "Could not determine ucxx version. Contents of UCXX_VERSION file:\n${_ucxx_version_formatted}"
  )
endif()
file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/../UCXX_BRANCH" UCXX_BRANCH)
if(NOT UCXX_BRANCH)
  message(
    FATAL_ERROR
      "Could not determine branch name to use for ucxx. The file \"${CMAKE_CURRENT_LIST_DIR}/../UCXX_BRANCH\" is missing."
  )
endif()
# Don't use sccache-dist for CMake's compiler tests
set(ENV{SCCACHE_NO_DIST_COMPILE} "1")

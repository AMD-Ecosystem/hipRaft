#!/bin/bash

# Copyright (c) 2023-2024, NVIDIA CORPORATION.

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
#
# raft empty project template build script

#-----------------------------------------------------------------------------
# The following environment variables can be set to configure the build
# PARALLEL_LEVEL: Maximum number of parallel build jobs
# BUILD_TYPE: CMake build type (default: Release)
# BUILD_DIR: The build directory (default: <src-dir>/build)
# RAFT_REPO_REL: The path to locally available raft sources. If unspecified, the
#                source is downloaded from github. Please refer to
#                'cmake/get_raft.cmake' for further configuration options.
# EXTRA_CMAKE_ARGS: Extra options to be passed to CMake. Specify in the form of
#                   "-D<CMAKE_VAR1>=v1 -D<CMAKE_VAR2>=v2 ..."
#

# Abort script on first error
set -e

PARALLEL_LEVEL=${PARALLEL_LEVEL:=$(nproc)}

BUILD_TYPE="${BUILD_TYPE:="Release"}"
SOURCE_DIR="$(cd "$(dirname "$0")"; pwd)"
BUILD_DIR=${BUILD_DIR:="${SOURCE_DIR}/build/"}

if [[ ${RAFT_REPO_REL} != "" ]]; then
  RAFT_REPO_PATH="$(readlink -f "${RAFT_REPO_REL}")"
  EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DCPM_raft_SOURCE=${RAFT_REPO_PATH}"
fi

if [ "$1" == "clean" ]; then
  rm -rf "$BUILD_DIR"
  exit 0
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

export CC=hipcc
export CXX=hipcc

cmake \
 -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
 -DCMAKE_HIP_ARCHITECTURES="NATIVE" \
 -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
 "${EXTRA_CMAKE_ARGS}" \
" ${SOURCE_DIR}/cpp"

cmake  --build . -j"${PARALLEL_LEVEL}"

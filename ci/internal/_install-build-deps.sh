# shellcheck shell=bash
# MIT License
#
# Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.
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

# Install build dependencies for hipRAFT.
# Meant to be sourced, not executed directly.
#
# The build runs with --no-build-isolation, so pip installs nothing from the
# packages' own requires tables: everything they declare has to be here.
# verify_build_requires() in _wheel-helpers.sh checks that per package.
#
# Required environment variables:
#   BUILD_ARTIFACTS_DIR -- directory containing pre-built dependency wheels
#   HIPRAFT_BUILD_TYPE  -- controls which dependencies to install
#
# Optional environment variables:
#   CMAKE_VERSION         -- pins cmake
#   ROCMDS_LOGGER_VERSION -- pins amd-rocmds-logger
#   HIPMM_VERSION         -- pins amd-libhipmm and amd-hipmm
#   UCXX_VERSION          -- pins amd-libhipucxx
#                            CI sets these from the builder-tester
#                            _envs/rocmds/<branch> env file, and a bare checkout
#                            without them installs unpinned

set -euo pipefail

pip install --upgrade pip

case "${HIPRAFT_BUILD_TYPE:-}" in
  all|cpp_py|cpp_wheels|wheels|install_all|install_cpp_py|install_cpp_wheels)
    # pylibraft's .pyx files cimport rmm.librmm.cuda_stream_pool from the hipMM
    # wheels and cuda.bindings.cyruntime from the hip-python set, and
    # raft-dask's cmake resolves librmm through amd-libhipmm's cmake prefix.
    # The ucxx that raft_distributed links comes from amd-libhipucxx's cmake
    # prefix the same way.
    #
    # The rocm-bindings-* / hip-python-interop set stays unpinned: their version
    # leads with the ROCm version of the base image, which no env key names.
    pip install --no-deps \
        --find-links "${BUILD_ARTIFACTS_DIR}" \
        "amd-rocmds-logger${ROCMDS_LOGGER_VERSION:+==${ROCMDS_LOGGER_VERSION}}" \
        "amd-libhipmm${HIPMM_VERSION:+==${HIPMM_VERSION}}" \
        "amd-hipmm${HIPMM_VERSION:+==${HIPMM_VERSION}}" \
        "amd-libhipucxx${UCXX_VERSION:+==${UCXX_VERSION}}" \
        rocm-bindings-core \
        rocm-bindings-hip \
        hip-python-interop
    ;;
esac

pip install wheel auditwheel Cython scikit-build-core patchelf
pip install --force-reinstall "cmake${CMAKE_VERSION:+==${CMAKE_VERSION}}"
pip install ninja

pip install rapids-build-backend

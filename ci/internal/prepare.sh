#!/usr/bin/env bash

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

# Prepare the build environment: install OS packages, cmake, UCX, and OpenMPI.
#
# Required environment variables:
#   HIPRAFT_UCX_PREINSTALLED, HIPRAFT_OPENMPI_PREINSTALLED,
#   INSTALL_DIR, CMAKE_VERSION, ROCM_SPECIFIER
#
# Optional environment variables:
#   HIPRAFT_UCX_FULL_VERSION       -- UCX version (default: 1.17.0)
#   HIPRAFT_OPENMPI_MAJOR_VERSION  -- OpenMPI major version dir (default: v5.0)
#   HIPRAFT_OPENMPI_FULL_VERSION   -- OpenMPI full version (default: 5.0.6)
#   HIPRAFT_OPENMPI_STAGING_DIR    -- if set, `make install DESTDIR=...` here in
#                                     addition to installing into the prefix, so
#                                     a caller can export this tree as a build
#                                     artifact (e.g. for a companion tester image)
#   ROCM_HOME                      -- ROCm installation path
#   MAX_JOBS                       -- parallel make jobs

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_activate-env.sh"
require_envs HIPRAFT_UCX_PREINSTALLED HIPRAFT_OPENMPI_PREINSTALLED INSTALL_DIR CMAKE_VERSION ROCM_SPECIFIER

HIPRAFT_UCX_FULL_VERSION="${HIPRAFT_UCX_FULL_VERSION:-1.17.0}"
HIPRAFT_OPENMPI_MAJOR_VERSION="${HIPRAFT_OPENMPI_MAJOR_VERSION:-v5.0}"
HIPRAFT_OPENMPI_FULL_VERSION="${HIPRAFT_OPENMPI_FULL_VERSION:-5.0.6}"

os_id=$(. /etc/os-release; echo "$ID")
os_id_like=$(. /etc/os-release; echo "$ID_LIKE")

if [[ "${os_id}" == *"ubuntu"* ]]; then
    apt install -y libblas-dev liblapack-dev ninja-build libsuitesparse-dev patchelf
elif [[ "${os_id_like}" == *"rhel"* ]]; then
    dnf install -y openblas-devel lapack-devel ninja-build suitesparse-devel patchelf
fi

# Prepare the build environment. Prefer the conda env created by the pipeline
# (when HIPRAFT_CONDA_ENV is set); otherwise fall back to a dedicated python venv.
if ! activate_hipraft_conda_env; then
    python3 -m venv --clear "${INSTALL_DIR}/venv/hipraft_dev"
    activate_hipraft_venv
fi
pip install --upgrade pip
pip install --force-reinstall cmake${CMAKE_VERSION:+==${CMAKE_VERSION}}
pip install scikit-build-core auditwheel cython pytest "numba<0.62" fastrlock

if [[ "${HIPRAFT_UCX_PREINSTALLED}" == "false" ]]; then
    wget "https://github.com/openucx/ucx/releases/download/v${HIPRAFT_UCX_FULL_VERSION}/ucx-${HIPRAFT_UCX_FULL_VERSION}.tar.gz"
    tar xzf "ucx-${HIPRAFT_UCX_FULL_VERSION}.tar.gz"
    cd "ucx-${HIPRAFT_UCX_FULL_VERSION}"
    env -i PATH="${PATH}" CC=gcc CXX=g++ ./contrib/configure-release --prefix=/usr --with-rocm="${ROCM_HOME}"
    make -j "${MAX_JOBS}"
    make install
    cd -
    rm -rf ucx*
fi

if [[ "${HIPRAFT_OPENMPI_PREINSTALLED}" == "false" ]]; then
    wget "https://download.open-mpi.org/release/open-mpi/${HIPRAFT_OPENMPI_MAJOR_VERSION}/openmpi-${HIPRAFT_OPENMPI_FULL_VERSION}.tar.bz2"
    bzip2 -d "openmpi-${HIPRAFT_OPENMPI_FULL_VERSION}.tar.bz2"
    tar -xvf "openmpi-${HIPRAFT_OPENMPI_FULL_VERSION}.tar"
    cd "openmpi-${HIPRAFT_OPENMPI_FULL_VERSION}"
    # GCC 14 defaults to gnu23, which promotes implicit-function-declaration to
    # a hard error; this version's ROCm accelerator module calls memcpy()
    # without including <string.h> (open-mpi/ompi#13476).
    env -i PATH="${PATH}" CC=gcc CXX=g++ \
        CFLAGS="-Wno-error=implicit-function-declaration -Wno-error=int-conversion" \
        ./configure --prefix=/usr --with-ucx=/usr --with-rocm="${ROCM_HOME}"
    env -i PATH="${PATH}" CC=gcc CXX=g++ make -j "${MAX_JOBS}"
    if [[ -n "${HIPRAFT_OPENMPI_STAGING_DIR:-}" ]]; then
        env -i PATH="${PATH}" CC=gcc CXX=g++ make install DESTDIR="${HIPRAFT_OPENMPI_STAGING_DIR}"
        cp -a "${HIPRAFT_OPENMPI_STAGING_DIR}"/* /
    else
        env -i PATH="${PATH}" CC=gcc CXX=g++ make install
    fi
    cd -
    rm -rf openmpi*
fi

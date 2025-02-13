# syntax=docker/dockerfile:1.5

# MIT License
#
# Copyright (c) 2024-2025 Advanced Micro Devices, Inc.
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

ARG UBUNTU="24.04"

# AMD dev images ubuntu-dev-<UBUNTU_VER>:<ROCM_VER>-complete do not work.
# see internal issue #26.
ARG BASE=ubuntu:${UBUNTU}

FROM ${BASE}

# Args used before a FROM statement are reset. Adding another ARG here keeps the default value the same, and
# when specifying --build-arg UBUNTU=<SOME_VAL>, SOME_VAL is applied to both UBUNTU args.
ARG UBUNTU="24.04"

ARG GITHUB_USER
ARG GITHUB_PASS
ARG ROCM=6.3

ENV GITHUB_USER=${GITHUB_USER}
ENV GITHUB_PASS=${GITHUB_PASS}
ENV ROCM=${ROCM}

#Ensures that if any stage in a pipe fails, that the entire RUN command fails
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN set -o pipefail && apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        sudo \
        vim \
        python3 \
        software-properties-common \
        git-all \
        bash-completion \
        ninja-build \
        libblas-dev \
        liblapack-dev \
        wget \
        ca-certificates \
        clang-format \
        gpg && \
    wget -q -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
        | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc

RUN UBUNTU_NAME="UNKNOWN" && \
    if [ "${UBUNTU}" = "22.04" ]; then \
        UBUNTU_NAME="jammy"; \
    elif [ "${UBUNTU}" = "24.04" ]; then \
        UBUNTU_NAME="noble"; \
    else \
        echo "Unknown Ubuntu version"; \
    fi && \
    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${UBUNTU_NAME} main"  \
        | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    wget -q https://repo.radeon.com/amdgpu-install/${ROCM}.1/ubuntu/${UBUNTU_NAME}/amdgpu-install_${ROCM}.60301-1_all.deb && \
    apt-get update && \
    # Dpkg option specification is to use new confs. Sometimes during image build there is a config prompt that breaks the build. This line avoids that
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends -o "Dpkg::Options::=--force-confnew" \
             cmake \
             ./amdgpu-install_${ROCM}.60301-1_all.deb && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN DEBIAN_FRONTEND=noninteractive amdgpu-install -y \
    --usecase="graphics,opencl,hip,rocm,rocmdev,rocmdevtools,lrt,opencl,hiplibsdk" \
    --no-dkms && \
    apt-get clean && \
    rm amdgpu-install_${ROCM}.60301-1_all.deb

ENV CMAKE_PREFIX_PATH="/opt/rocm/lib/cmake"

WORKDIR /third_party_builds

RUN  git config --global credential.helper store && \
     echo "https://${GITHUB_USER}:${GITHUB_PASS}@github.com" > ~/.git-credentials && \
     git clone https://github.com/ROCmSoftwarePlatform/rocPRIM.git && \
     wget -q https://github.com/openucx/ucx/releases/download/v1.17.0/ucx-1.17.0.tar.gz && \
     wget -q https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.6.tar.bz2

RUN tar xzf ucx-1.17.0.tar.gz && \
    cd ucx-1.17.0 && \
    ./contrib/configure-release --prefix=/usr --with-rocm=/opt/rocm && \
    make -j32 && \
    make install

RUN bzip2 -d openmpi-5.0.6.tar.bz2 && \
    tar -xvf openmpi-5.0.6.tar && \
    cd openmpi-5.0.6 && \
    ./configure --prefix=/usr --with-ucx=/usr --with-rocm=/opt/rocm && \
    make -j $(nproc) && \
    make install

WORKDIR /home

RUN rm -rf /third_party_builds

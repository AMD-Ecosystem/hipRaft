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

# Build hipRAFT Python wheels (amd-libraft, amd-pylibraft and amd-raft-dask).
#
# Required environment variables:
#   PROJECT_ID, SRC_DIR, BUILD_DIR, INSTALL_DIR, BUILD_ARTIFACTS_DIR
#   AMDGPU_TARGETS -- GPU architectures to target
#   ROCM_PATH
#
# Optional environment variables:
#   HIPRAFT_BUILD_TYPE, CMAKE_VERSION
#   HIPRAFT_VERSION -- pins the wheels this build installs from BUILD_ARTIFACTS_DIR
#   HIPMM_VERSION   -- pins the hipMM wheels _install-build-deps.sh resolves
#   CMAKE_INSTALL_PREFIX -- overrides INSTALL_DIR as the install prefix
#   USE_SABI -- "no", or the CPython version to use as the stable-ABI (abi3)
#               floor for the Cython wheels, e.g. "3.12". A floor tags the wheel
#               cp<floor>-abi3, so it installs on that CPython and every later
#               one; "no" builds against the running interpreter alone and tags
#               it cp3XX-cp3XX. amd-libraft is py3-none in every case.
#   HIPRAFT_BUILD_LIBRAFT, HIPRAFT_BUILD_PYLIBRAFT, HIPRAFT_BUILD_RAFT_DASK --
#               all three wheels are built unless one of these is set empty.
#               amd-libraft is py3-none and needs one build, while the other two
#               carry Cython extensions and need one per interpreter, so the
#               matrix driver asks for them separately. Only an empty value
#               skips a wheel; any other value, "0" included, builds it.

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_wheel-helpers.sh"
: "${PROJECT_ID:?PROJECT_ID must be set}"
: "${SRC_DIR:?SRC_DIR must be set}"
: "${BUILD_DIR:?BUILD_DIR must be set}"
: "${INSTALL_DIR:?INSTALL_DIR must be set}"
: "${BUILD_ARTIFACTS_DIR:?BUILD_ARTIFACTS_DIR must be set}"
: "${AMDGPU_TARGETS:?AMDGPU_TARGETS must be set}"
: "${ROCM_PATH:?ROCM_PATH must be set}"

# Bare '-', not ':-': an empty value is the one that means skip, so it has to
# survive the default.
build_libraft=${HIPRAFT_BUILD_LIBRAFT-1}
build_pylibraft=${HIPRAFT_BUILD_PYLIBRAFT-1}
build_raft_dask=${HIPRAFT_BUILD_RAFT_DASK-1}

### stable-ABI floor for the Cython wheels
#
# python/pylibraft and python/raft-dask pin wheel.py-api = "cp311", so both
# directions are an override here: a floor replaces the pin, and "no", the
# default, clears it for a tag specific to the building interpreter. Clearing
# travels as a config-setting because scikit-build-core reads an empty value
# from there but not from the environment, where empty is indistinguishable
# from unset.

if [ "${USE_SABI:-no}" = "no" ]; then
  cython_wheel_config=(--config-settings=skbuild.wheel.py-api=)
else
  cython_wheel_config=("--config-settings=skbuild.wheel.py-api=cp${USE_SABI//./}")
fi

src_dir=${SRC_DIR}/${PROJECT_ID}
wheels_build_dir=${BUILD_DIR}/_WHEELS_/
build_dir="${wheels_build_dir}/${PROJECT_ID}"

mkdir -p "${wheels_build_dir}"
cp -va "${src_dir}/." "${build_dir}/"

cd "${build_dir}"
    . "${SCRIPT_DIR}/_build-preamble.sh"

    cmake_args+=(
      "-DCMAKE_CXX_COMPILER=hipcc"
    )

    SKBUILD_CMAKE_ARGS="$(IFS=';'; echo "${cmake_args[*]}")"
    export SKBUILD_CMAKE_ARGS

    ### the GPU architectures, which cannot travel in SKBUILD_CMAKE_ARGS
    #
    # scikit-build-core splits SKBUILD_CMAKE_ARGS on ';' and offers no escape,
    # so a multi-arch list -- the ';'-separated form CMAKE_HIP_ARCHITECTURES
    # itself wants -- is torn apart: "-DCMAKE_HIP_ARCHITECTURES=gfx90a;gfx942"
    # arrives as "-DCMAKE_HIP_ARCHITECTURES=gfx90a" plus a stray "gfx942" that
    # cmake ignores. The wheel then carries code objects for the first arch
    # alone and every kernel launch on any other one fails at runtime with
    # hipErrorInvalidImage / hipErrorInvalidKernelFile, a stage and a container
    # after the build that caused it.
    #
    # CMAKE_ARGS is the env vehicle that survives: scikit-build-core shlex-
    # splits it, i.e. on whitespace, so ';' passes through untouched. Normalize
    # ',' and whitespace to ';' first, because AMDGPU_TARGETS is written in all
    # three forms and only ';' is a CMake list.
    hip_architectures=$(echo "${AMDGPU_TARGETS}" | tr ',' ' ' | xargs | tr ' ' ';')
    CMAKE_ARGS="${CMAKE_ARGS:+${CMAKE_ARGS} }-DCMAKE_HIP_ARCHITECTURES=${hip_architectures} -DGPU_TARGETS=${hip_architectures}"
    export CMAKE_ARGS
    export HIP_PLATFORM=amd
    export RAPIDS_DISABLE_CUDA=true
    export WHEEL_BUILD_ROOT="${build_dir}"

    wheels_build_env=$(mktemp -d)
    python3 -m venv "${wheels_build_env}"
    . "${wheels_build_env}/bin/activate"

        . "${SCRIPT_DIR}/_install-build-deps.sh"

        # 1) build amd-libraft, which carries libraft.so and the cmake config
        # the other two resolve raft through.
        if [ -n "${build_libraft}" ]; then
          build_rapids_wheel "python/libraft"
        fi

        # 2) build amd-pylibraft against the libraft wheel, either the one built
        # above or the one an earlier libraft-only pass left behind.
        if [ -n "${build_pylibraft}" ]; then
          install_built_wheel --no-deps --no-index -- \
            "amd_libraft${HIPRAFT_VERSION:+==${HIPRAFT_VERSION}}"

          build_rapids_wheel "python/pylibraft" "" "${cython_wheel_config[@]}"
        fi

        # 3) build amd-raft-dask. Its cmake asks for the raft 'distributed'
        # component, so it needs the same libraft wheel, and its Cython layer
        # is built against pylibraft.
        if [ -n "${build_raft_dask}" ]; then
          install_built_wheel --no-deps --no-index -- \
            "amd_libraft${HIPRAFT_VERSION:+==${HIPRAFT_VERSION}}" \
            "amd_pylibraft${HIPRAFT_VERSION:+==${HIPRAFT_VERSION}}"

          build_rapids_wheel "python/raft-dask" "" "${cython_wheel_config[@]}"
        fi

    # cleanup
    deactivate # deactivate venv
    rm -rf "${wheels_build_env}"

rm -rf "${build_dir}"

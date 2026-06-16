#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2026 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Build hipRAFT components based on HIPRAFT_BUILD_TYPE.
#
# Required environment variables:
#   HIPRAFT_BUILD_TYPE  -- build scope (cpp, cpp_py, install_cpp, install_cpp_py, examples, all, install_all)
#   PROJECT_ID, SRC_DIR, BUILD_DIR, INSTALL_DIR, ROCM_PATH, AMDGPU_TARGETS,
#   BUILD_ARTIFACTS_DIR, CMAKE_INSTALL_PREFIX
#
# Optional environment variables:
#   HIPRAFT_USE_VERSIONS_JSON  -- fetch deps via versions.json instead of /src/ (default: false)
#   HIPRAFT_BUILD_TESTS        -- build C++ tests (default: true)
#   HIPRAFT_BUILD_BENCH_PRIMS  -- build bench-prims (default: true)
#   SCCACHE_ENABLE             -- use sccache as compiler launcher (default: false)

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"
require_envs HIPRAFT_BUILD_TYPE PROJECT_ID SRC_DIR BUILD_DIR INSTALL_DIR ROCM_PATH AMDGPU_TARGETS BUILD_ARTIFACTS_DIR CMAKE_INSTALL_PREFIX

# Prefer the conda env (HIPRAFT_CONDA_ENV) when set; otherwise use the venv.
if ! activate_hipraft_conda_env; then
    activate_hipraft_venv
fi

if [ -d "/opt/rh/gcc-toolset-$(g++ -dumpversion)" ]; then
  toolchain="/opt/rh/gcc-toolset-$(g++ -dumpversion)/root/usr"
  export CCC_OVERRIDE_OPTIONS="+--gcc-toolchain=${toolchain}"
  # note: in some shells, cmake is using /bin/{cc, c++} as compilers,
  # which may not be the compilers of the enabled toolchain.
  export CC=${toolchain}/bin/cc
  # export CXX=${toolchain}/bin/c++
fi

printenv

build_cpp() {
    mkdir -p "${BUILD_DIR}/${PROJECT_ID}"
    rm -rf "${BUILD_DIR:?}/${PROJECT_ID}"
    cp -R "${SRC_DIR}/${PROJECT_ID}" "${BUILD_DIR}/${PROJECT_ID}"

    cd "${BUILD_DIR}/${PROJECT_ID}"

    local cmake_args=()
    if [[ "${CMAKE_INSTALL_PREFIX:-}" == "<conda-prefix>" ]]; then
        cmake_args+=("-DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX}")
    elif [[ -n "${CMAKE_INSTALL_PREFIX:-}" ]]; then
        cmake_args+=("-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}")
    fi

    if [[ "${HIPRAFT_USE_VERSIONS_JSON:-false}" == "false" ]]; then
        cmake_args+=("-DCPM_libhipcxx_SOURCE=${SRC_DIR}/libhipcxx")
        cmake_args+=("-DCPM_cuco_SOURCE=${SRC_DIR}/hipcollections")
        cmake_args+=("-DCPM_rmm_SOURCE=${SRC_DIR}/hipmm")
        cmake_args+=("-DCPM_rapids_logger_SOURCE=${SRC_DIR}/rocmds_logger")
    fi

    if [[ "${SCCACHE_ENABLE:-false}" == "true" ]]; then
        cmake_args+=("-DCMAKE_HIP_COMPILER_LAUNCHER=sccache")
        cmake_args+=("-DCMAKE_CXX_COMPILER_LAUNCHER=sccache")
        cmake_args+=("-DCMAKE_C_COMPILER_LAUNCHER=sccache")
    fi

    # Only skip install for cpp-only builds; wheel builds require libraft installed.
    local no_install=""
    if [[ "${HIPRAFT_BUILD_TYPE}" == "cpp" ]]; then
        no_install=1
    fi

    local build_sh_args=(libraft --compile-lib ${no_install:+"-n"})

    if [[ "${HIPRAFT_BUILD_TESTS:-true}" == "true" ]]; then
        build_sh_args+=(tests)
    fi

    if [[ "${HIPRAFT_BUILD_BENCH_PRIMS:-true}" == "true" ]]; then
        build_sh_args+=(bench-prims)
    fi

    if [[ -n "${AMDGPU_TARGETS}" ]]; then
        build_sh_args+=("--gpu-arch=${AMDGPU_TARGETS}")
    fi

    if [[ ${#cmake_args[@]} -gt 0 ]]; then
        build_sh_args+=("--cmake-args=\"${cmake_args[*]}\"")
    fi

    local os_id
    os_id=$(. /etc/os-release; echo "$ID")
    if [[ "${os_id}" == *"almalinux"* ]]; then
        export CMAKE_GENERATOR="Unix Makefiles"
    fi

    CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-}:${ROCM_PATH}/lib/cmake" \
        bash build.sh "${build_sh_args[@]}"
}

build_wheels() {
    mkdir -p "${BUILD_DIR}/${PROJECT_ID}"
    if [[ ! -d "${BUILD_DIR}/${PROJECT_ID}/.git" ]]; then
        rm -rf "${BUILD_DIR:?}/${PROJECT_ID}"
        cp -R "${SRC_DIR}/${PROJECT_ID}" "${BUILD_DIR}/${PROJECT_ID}"
    fi

    cd "${BUILD_DIR}/${PROJECT_ID}"

    if [[ -d "${BUILD_ARTIFACTS_DIR}" ]]; then
        # Enable nullglob to handle missing wheel files gracefully
        local old_nullglob
        old_nullglob=$(shopt -p nullglob || true)
        shopt -s nullglob

        local wheels=(
            "${BUILD_ARTIFACTS_DIR}"/hip_python*.whl
            "${BUILD_ARTIFACTS_DIR}"/rocm_bindings*.whl
            "${BUILD_ARTIFACTS_DIR}"/*rocmds_logger*.whl
            "${BUILD_ARTIFACTS_DIR}"/numba_hip*.whl
            "${BUILD_ARTIFACTS_DIR}"/*cupy*.whl
            "${BUILD_ARTIFACTS_DIR}"/*hipmm*.whl
        )

        # Restore original nullglob setting
        ${old_nullglob}

        if [[ ${#wheels[@]} -gt 0 ]]; then
            pip install --find-links "${BUILD_ARTIFACTS_DIR}" --no-deps "${wheels[@]}"
        else
            echo "WARNING: No artifact wheels found in ${BUILD_ARTIFACTS_DIR}, falling back to PyPI"
            pip install hip-python numba-hip amd-cupy amd-hipmm amd-libhipmm
            pip install hip-python-as-cuda || true
            pip install hip-python-interop || true
        fi
    else
        pip install hip-python numba-hip amd-cupy amd-hipmm amd-libhipmm
        pip install hip-python-as-cuda || true
        pip install hip-python-interop || true
    fi

    local install_prefix="${CMAKE_INSTALL_PREFIX}"
    if [[ "${install_prefix}" == "<conda-prefix>" ]]; then
        install_prefix="${CONDA_PREFIX}"
    fi

    local cmake_args=(
        "-DCMAKE_CXX_COMPILER=hipcc"
        "-DCMAKE_PREFIX_PATH=${install_prefix}"
    )

    if [[ -n "${AMDGPU_TARGETS}" ]]; then
        cmake_args+=("-DCMAKE_HIP_ARCHITECTURES=${AMDGPU_TARGETS}")
    fi

    if [[ "${HIPRAFT_USE_VERSIONS_JSON:-false}" == "false" ]]; then
        cmake_args+=("-DCPM_libhipcxx_SOURCE=${SRC_DIR}/libhipcxx")
        cmake_args+=("-DCPM_cuco_SOURCE=${SRC_DIR}/hipcollections")
        cmake_args+=("-DCPM_rmm_SOURCE=${SRC_DIR}/hipmm")
        cmake_args+=("-DCPM_rapids_logger_SOURCE=${SRC_DIR}/rocmds_logger")
    fi

    if [[ "${SCCACHE_ENABLE:-false}" == "true" ]]; then
        cmake_args+=("-DCMAKE_HIP_COMPILER_LAUNCHER=sccache")
        cmake_args+=("-DCMAKE_CXX_COMPILER_LAUNCHER=sccache")
        cmake_args+=("-DCMAKE_C_COMPILER_LAUNCHER=sccache")
    fi

    local os_id
    os_id=$(. /etc/os-release; echo "$ID")
    if [[ "${os_id}" == *"almalinux"* ]]; then
        export CMAKE_GENERATOR="Unix Makefiles"
    fi

    export HIP_PLATFORM=amd
    export SKBUILD_CMAKE_ARGS
    SKBUILD_CMAKE_ARGS=$(IFS=';'; echo "${cmake_args[*]}")

    local dist_dir
    dist_dir=$(mktemp -d)

    CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-}:${ROCM_PATH}/lib/cmake" \
        python -m pip wheel --no-deps --no-build-isolation --wheel-dir "${dist_dir}" python/libraft
    python -m auditwheel repair --exclude "*" -w "${BUILD_ARTIFACTS_DIR}" "${dist_dir}"/*
    rm -rf "${dist_dir}"

    if [[ "${HIPRAFT_BUILD_TYPE}" == "install"* ]]; then
        pip install --no-deps "${BUILD_ARTIFACTS_DIR}"/amd_libraft*.whl
    fi

    dist_dir=$(mktemp -d)
    CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-}:${ROCM_PATH}/lib/cmake" \
        python -m pip wheel --no-deps --no-build-isolation --wheel-dir "${dist_dir}" python/pylibraft
    python -m auditwheel repair --exclude "*" -w "${BUILD_ARTIFACTS_DIR}" "${dist_dir}"/*
    rm -rf "${dist_dir}"

    if [[ "${HIPRAFT_BUILD_TYPE}" == "install"* ]]; then
        pip install --no-deps "${BUILD_ARTIFACTS_DIR}"/amd_pylibraft*.whl
    fi
}

build_examples() {
    if [[ ! -d "${BUILD_DIR}/${PROJECT_ID}" ]]; then
        cp -R "${SRC_DIR}/${PROJECT_ID}" "${BUILD_DIR}/${PROJECT_ID}"
    fi

    cd "${BUILD_DIR}/${PROJECT_ID}"

    local cmake_args=()
    if [[ "${HIPRAFT_USE_VERSIONS_JSON:-false}" == "false" ]]; then
        cmake_args+=("-DCPM_libhipcxx_SOURCE=${SRC_DIR}/libhipcxx")
        cmake_args+=("-DCPM_cuco_SOURCE=${SRC_DIR}/hipcollections")
        cmake_args+=("-DCPM_rmm_SOURCE=${SRC_DIR}/hipmm")
        cmake_args+=("-DCPM_rapids_logger_SOURCE=${SRC_DIR}/rocmds_logger")
    fi

    if [[ "${SCCACHE_ENABLE:-false}" == "true" ]]; then
        cmake_args+=("-DCMAKE_HIP_COMPILER_LAUNCHER=sccache")
        cmake_args+=("-DCMAKE_CXX_COMPILER_LAUNCHER=sccache")
        cmake_args+=("-DCMAKE_C_COMPILER_LAUNCHER=sccache")
    fi

    CC=hipcc CXX=hipcc CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-}:${ROCM_PATH}/lib/cmake" \
        cmake \
        -DCMAKE_HIP_ARCHITECTURES="${AMDGPU_TARGETS}" \
        -DCPM_raft_SOURCE="$(pwd)" \
        -DCMAKE_USER_MAKE_RULES_OVERRIDE="$(readlink -f overrides.cmake)" \
        ${cmake_args[@]:+"${cmake_args[@]}"} \
        -S "$(pwd)/examples/cpp" \
        -B "$(pwd)/examples/build"

    cmake --build "$(pwd)/examples/build"
}

case "${HIPRAFT_BUILD_TYPE}" in
    cpp|install_cpp)
        build_cpp
        ;;
    cpp_py|install_cpp_py)
        build_cpp
        build_wheels
        ;;
    examples)
        build_examples
        ;;
    all|install_all)
        build_cpp
        build_wheels
        build_examples
        ;;
    *)
        echo "ERROR: unknown HIPRAFT_BUILD_TYPE '${HIPRAFT_BUILD_TYPE}'" >&2
        exit 1
        ;;
esac

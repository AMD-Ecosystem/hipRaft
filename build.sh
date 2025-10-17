#!/bin/bash

# Copyright (c) 2020-2024, NVIDIA CORPORATION.

# Modifications Copyright (c) 2024-2025 Advanced Micro Devices, Inc.
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
# raft build scripts

# This script is used to build the component(s) in this repo from
# source, and can be called with various options to customize the
# build as needed (see the help output for details)

# Abort script on first error
set -e

NUMARGS=$#
ARGS=$*

# NOTE: ensure all dir changes are relative to the location of this
# scripts, and that this script resides in the repo dir!
REPODIR=$(cd $(dirname $0); pwd)

VALIDARGS="clean libraft pylibraft docs tests template package bench-prims examples --uninstall  -v -g -n --compile-lib --compile-static-lib --allgpuarch --show_depr_warn -h"
HELP="$0 [<target> ...] [<flag> ...] [--cmake-args=\"<args>\"] [--cache-tool=<tool>] [--limit-tests=<targets>] [--build-metrics=<filename>] [--gpu-arch="arch"]
 where <target> is:
   clean            - remove all existing build artifacts and configuration (start over)
   libraft          - build the raft C++ code only. Also builds the C-wrapper library
                      around the C++ code.
   pylibraft        - build the pylibraft Python package
   docs             - build the documentation
   tests            - build the tests
   bench-prims      - build micro-benchmarks for primitives
   examples         - build C++ examples

 and <flag> is:
   -v                          - verbose build mode
   -g                          - build for debug
   -n                          - no install step
   --uninstall                 - uninstall files for specified targets which were built and installed prior
   --compile-lib               - compile shared library for all components
   --compile-static-lib        - compile static library for all components
   --cpu-only                  - build CPU only components without HIP/CUDA. Applies to bench-ann only currently.
   --limit-tests               - semicolon-separated list of test executables to compile (e.g. NEIGHBORS_TEST;CLUSTER_TEST)
   --limit-bench-prims         - semicolon-separated list of prims benchmark executables to compute (e.g. NEIGHBORS_PRIMS_BENCH;CLUSTER_PRIMS_BENCH)
   --allgpuarch                - build for all supported GPU architectures
   --gpu-arch=\"arch\"           - build for specific GPU architectures e.g --gpu-arch=\"gfx90a\"
   --show_depr_warn            - show cmake deprecation warnings
   --build-metrics             - filename for generating build metrics report for libraft
   --cmake-args=\\\"<args>\\\"     - pass arbitrary list of CMake configuration options (escape all quotes in argument)
   --cache-tool=<tool>         - pass the build cache tool (eg: ccache, sccache, distcc) that will be used
                                 to speedup the build process.
   -h                          - print this text

 default action (no args) is to build libraft, tests, pylibraft and raft-dask targets
"
LIBRAFT_BUILD_DIR=${LIBRAFT_BUILD_DIR:=${REPODIR}/cpp/build}
EXAMPLES_BUILD_DIR=${REPODIR}/examples/build
SPHINX_BUILD_DIR=${REPODIR}/docs
RAFT_DASK_BUILD_DIR=${REPODIR}/python/raft-dask/_skbuild
PYLIBRAFT_BUILD_DIR=${REPODIR}/python/pylibraft/_skbuild
BUILD_DIRS="${LIBRAFT_BUILD_DIR} ${PYLIBRAFT_BUILD_DIR} ${RAFT_DASK_BUILD_DIR} ${EXAMPLES_BUILD_DIR}"

# Set defaults for vars modified by flags to this script
CMAKE_LOG_LEVEL=""
VERBOSE_FLAG=""
BUILD_ALL_GPU_ARCH=0
BUILD_TESTS=OFF
BUILD_TYPE=Release
BUILD_PRIMS_BENCH=OFF
COMPILE_LIBRARY=OFF
INSTALL_TARGET=install
BUILD_REPORT_METRICS=""
BUILD_REPORT_INCL_CACHE_STATS=OFF

TEST_TARGETS="CORE_TEST;SPARSE_TEST;LINALG_TEST;RANDOM_TEST;SOLVERS_TEST;STATS_TEST;MATRIX_TEST;MATRIX_SELECT_TEST;MATRIX_SELECT_LARGE_TEST;UTILS_TEST;LABEL_TEST;RUNTIME_RANDOM_TEST;NEIGHBORS_UTILS_TEST;SRC_LINALG_TEST"

CACHE_ARGS=""
LOG_COMPILE_TIME=OFF
CLEAN=0
UNINSTALL=0
DISABLE_DEPRECATION_WARNINGS=ON
CMAKE_TARGET=""
# FIXME(HIP/AMD): rocThrust/rocPrim require CXX compiler to be equal to hipcc
EXTRA_CMAKE_HIP_ARGS="-DCMAKE_CXX_COMPILER=hipcc"

# Set defaults for vars that may not have been defined externally
INSTALL_PREFIX=${INSTALL_PREFIX:=${PREFIX:=${CONDA_PREFIX:=$LIBRAFT_BUILD_DIR/install}}}
PARALLEL_LEVEL=${PARALLEL_LEVEL:=`nproc`}
BUILD_ABI=${BUILD_ABI:=ON}

# Default to Ninja if generator is not specified
export CMAKE_GENERATOR="${CMAKE_GENERATOR:=Ninja}"

function hasArg {
    (( ${NUMARGS} != 0 )) && (echo " ${ARGS} " | grep -q " $1 ")
}

function cmakeArgs {
    # Check for multiple cmake args options
    if [[ $(echo $ARGS | { grep -Eo "\-\-cmake\-args" || true; } | wc -l ) -gt 1 ]]; then
        echo "Multiple --cmake-args options were provided, please provide only one: ${ARGS}"
        exit 1
    fi

    # Check for cmake args option
    if [[ -n $(echo $ARGS | { grep -E "\-\-cmake\-args" || true; } ) ]]; then
        # There are possible weird edge cases that may cause this regex filter to output nothing and fail silently
        # the true pipe will catch any weird edge cases that may happen and will cause the program to fall back
        # on the invalid option error
        EXTRA_CMAKE_ARGS=$(echo $ARGS | { grep -Eo "\-\-cmake\-args=\".+\"" || true; })
        if [[ -n ${EXTRA_CMAKE_ARGS} ]]; then
            # Remove the full  EXTRA_CMAKE_ARGS argument from list of args so that it passes validArgs function
            ARGS=${ARGS//$EXTRA_CMAKE_ARGS/}
            # Filter the full argument down to just the extra string that will be added to cmake call
            EXTRA_CMAKE_ARGS=$(echo $EXTRA_CMAKE_ARGS | grep -Eo "\".+\"" | sed -e 's/^"//' -e 's/"$//')
        fi
    fi
}

function cacheTool {
    # Check for multiple cache options
    if [[ $(echo $ARGS | { grep -Eo "\-\-cache\-tool" || true; } | wc -l ) -gt 1 ]]; then
        echo "Multiple --cache-tool options were provided, please provide only one: ${ARGS}"
        exit 1
    fi
    # Check for cache tool option
    if [[ -n $(echo $ARGS | { grep -E "\-\-cache\-tool" || true; } ) ]]; then
        # There are possible weird edge cases that may cause this regex filter to output nothing and fail silently
        # the true pipe will catch any weird edge cases that may happen and will cause the program to fall back
        # on the invalid option error
        CACHE_TOOL=$(echo $ARGS | sed -e 's/.*--cache-tool=//' -e 's/ .*//')
        if [[ -n ${CACHE_TOOL} ]]; then
            # Remove the full CACHE_TOOL argument from list of args so that it passes validArgs function
            ARGS=${ARGS//--cache-tool=$CACHE_TOOL/}
            CACHE_ARGS="-DCMAKE_CUDA_COMPILER_LAUNCHER=${CACHE_TOOL} -DCMAKE_C_COMPILER_LAUNCHER=${CACHE_TOOL} -DCMAKE_CXX_COMPILER_LAUNCHER=${CACHE_TOOL}"
        fi
    fi
}

function limitTests {
    # Check for option to limit the set of test binaries to build
    if [[ -n $(echo $ARGS | { grep -E "\-\-limit\-tests" || true; } ) ]]; then
        # There are possible weird edge cases that may cause this regex filter to output nothing and fail silently
        # the true pipe will catch any weird edge cases that may happen and will cause the program to fall back
        # on the invalid option error
        LIMIT_TEST_TARGETS=$(echo $ARGS | sed -e 's/.*--limit-tests=//' -e 's/ .*//')
        if [[ -n ${LIMIT_TEST_TARGETS} ]]; then
            # Remove the full LIMIT_TEST_TARGETS argument from list of args so that it passes validArgs function
            ARGS=${ARGS//--limit-tests=$LIMIT_TEST_TARGETS/}
            TEST_TARGETS=${LIMIT_TEST_TARGETS}
            echo "Limiting tests to $TEST_TARGETS"
        fi
    fi
}

function limitBench {
    # Check for option to limit the set of test binaries to build
    if [[ -n $(echo $ARGS | { grep -E "\-\-limit\-bench-prims" || true; } ) ]]; then
        # There are possible weird edge cases that may cause this regex filter to output nothing and fail silently
        # the true pipe will catch any weird edge cases that may happen and will cause the program to fall back
        # on the invalid option error
        LIMIT_PRIMS_BENCH_TARGETS=$(echo $ARGS | sed -e 's/.*--limit-bench-prims=//' -e 's/ .*//')
        if [[ -n ${LIMIT_PRIMS_BENCH_TARGETS} ]]; then
            # Remove the full LIMIT_PRIMS_BENCH_TARGETS argument from list of args so that it passes validArgs function
            ARGS=${ARGS//--limit-bench-prims=$LIMIT_PRIMS_BENCH_TARGETS/}
            PRIMS_BENCH_TARGETS=${LIMIT_PRIMS_BENCH_TARGETS}
        fi
    fi
}

function gpuArch {
    # Check if both --gpu-arch and --allgpuarch are specified
    if hasArg --allgpuarch && [[ -n $(echo $ARGS | { grep -E "\-\-gpu\-arch" || true; } ) ]]; then
        echo "Error: Cannot specify both --gpu-arch and --allgpuarch"
        echo "Use either:"
        echo "  --gpu-arch=\"gfx90a;gfx942\"    (for specific architectures)"
        echo "  --allgpuarch        (for all supported architectures)"
        exit 1
    fi

    # Check for multiple gpu-arch options
    if [[ $(echo $ARGS | { grep -Eo "\-\-gpu\-arch" || true; } | wc -l ) -gt 1 ]]; then
        echo "Error: Multiple --gpu-arch options were provided. Please combine architectures into a single option."
        echo "Instead of: --gpu-arch=gfx90a --gpu-arch=gfx942"
        echo "Use:        --gpu-arch=\"gfx90a;gfx942\""
        exit 1
    fi

    # Check for gpu-arch option
    if [[ -n $(echo $ARGS | { grep -E "\-\-gpu\-arch" || true; } ) ]]; then
        GPU_ARCH_ARG=$(echo $ARGS | { grep -Eo "\-\-gpu\-arch=.+( |$)" || true; })
        if [[ -n ${GPU_ARCH_ARG} ]]; then
            # Remove the full argument from ARGS
            ARGS=${ARGS//$GPU_ARCH_ARG/}
            # Extract just the architecture value(just one for now)
            HIPRAFT_CMAKE_HIP_ARCHITECTURES=$(echo "$GPU_ARCH_ARG" | sed -e 's/--gpu-arch=//' -e "s/[\"']//g")
            echo "Building for specified GPU architectures: ${HIPRAFT_CMAKE_HIP_ARCHITECTURES}"
        fi
    fi
}

if hasArg -h || hasArg --help; then
    echo "${HELP}"
    exit 0
fi

# Check for valid usage
if (( ${NUMARGS} != 0 )); then
    cmakeArgs
    cacheTool
    limitTests
    limitBench
    gpuArch
    for a in ${ARGS}; do
        if ! (echo " ${VALIDARGS} " | grep -q " ${a} "); then
            echo "Invalid option: ${a}"
            exit 1
        fi
    done
fi

# This should run before build/install
if hasArg --uninstall; then
    UNINSTALL=1

    if hasArg pylibraft || hasArg libraft || (( ${NUMARGS} == 1 )); then

      echo "Removing libraft files..."
      if [ -e ${LIBRAFT_BUILD_DIR}/install_manifest.txt ]; then
          xargs rm -fv < ${LIBRAFT_BUILD_DIR}/install_manifest.txt > /dev/null 2>&1
      fi
    fi

    if hasArg pylibraft || (( ${NUMARGS} == 1 )); then
      echo "Uninstalling pylibraft package..."
      if [ -e ${PYLIBRAFT_BUILD_DIR}/install_manifest.txt ]; then
          xargs rm -fv < ${PYLIBRAFT_BUILD_DIR}/install_manifest.txt > /dev/null 2>&1
      fi

      # Try to uninstall via pip if it is installed
      if [ -x "$(command -v pip)" ]; then
        echo "Using pip to uninstall pylibraft"
        pip uninstall -y pylibraft

      # Otherwise, try to uninstall through conda if that's where things are installed
      elif [ -x "$(command -v conda)" ] && [ "$INSTALL_PREFIX" == "$CONDA_PREFIX" ]; then
        echo "Using conda to uninstall pylibraft"
        conda uninstall -y pylibraft

      # Otherwise, fail
      else
        echo "Could not uninstall pylibraft from pip or conda. pylibraft package will need to be manually uninstalled"
      fi
    fi

    if hasArg raft-dask || (( ${NUMARGS} == 1 )); then
      echo "Uninstalling raft-dask package..."
      if [ -e ${RAFT_DASK_BUILD_DIR}/install_manifest.txt ]; then
          xargs rm -fv < ${RAFT_DASK_BUILD_DIR}/install_manifest.txt > /dev/null 2>&1
      fi

      # Try to uninstall via pip if it is installed
      if [ -x "$(command -v pip)" ]; then
        echo "Using pip to uninstall raft-dask"
        pip uninstall -y raft-dask

      # Otherwise, try to uninstall through conda if that's where things are installed
      elif [ -x "$(command -v conda)" ] && [ "$INSTALL_PREFIX" == "$CONDA_PREFIX" ]; then
        echo "Using conda to uninstall raft-dask"
        conda uninstall -y raft-dask

      # Otherwise, fail
      else
        echo "Could not uninstall raft-dask from pip or conda. raft-dask package will need to be manually uninstalled."
      fi
    fi
    exit 0
fi


# Process flags
if hasArg -n; then
    INSTALL_TARGET=""
fi

if hasArg -v; then
    VERBOSE_FLAG="-v"
    CMAKE_LOG_LEVEL="VERBOSE"
fi
if hasArg -g; then
    BUILD_TYPE=Debug
fi

if hasArg --allgpuarch; then
    BUILD_ALL_GPU_ARCH=1
fi

if hasArg --compile-lib || (( ${NUMARGS} == 0 )); then
    COMPILE_LIBRARY=ON
    CMAKE_TARGET="${CMAKE_TARGET};raft_lib"
fi

if hasArg --compile-static-lib || (( ${NUMARGS} == 0 )); then
    COMPILE_LIBRARY=ON
    CMAKE_TARGET="${CMAKE_TARGET};raft_lib_static"
fi

if hasArg package; then
    CMAKE_TARGET="${CMAKE_TARGET};package"
fi

if hasArg tests || (( ${NUMARGS} == 0 )); then
    BUILD_TESTS=ON
    CMAKE_TARGET="${CMAKE_TARGET};${TEST_TARGETS}"

    # Force compile library when needed test targets are specified
    if [[ $CMAKE_TARGET == *"CLUSTER_TEST"* || \
          $CMAKE_TARGET == *"DISTANCE_TEST"* || \
          $CMAKE_TARGET == *"MATRIX_TEST"* || \
          $CMAKE_TARGET == *"NEIGHBORS_ANN_BRUTE_FORCE_TEST"* || \
          $CMAKE_TARGET == *"NEIGHBORS_ANN_CAGRA_TEST"* || \
          $CMAKE_TARGET == *"NEIGHBORS_ANN_IVF_TEST"* || \
          $CMAKE_TARGET == *"NEIGHBORS_ANN_NN_DESCENT_TEST"* || \
          $CMAKE_TARGET == *"NEIGHBORS_TEST"* || \
          $CMAKE_TARGET == *"RANDOM_SRC_TEST"* || \
          $CMAKE_TARGET == *"SPARSE_DIST_TEST" || \
          $CMAKE_TARGET == *"SPARSE_NEIGHBORS_TEST"* || \
          $CMAKE_TARGET == *"STATS_TEST"* ]]; then
      echo "-- Enabling compiled lib for gtests"
      COMPILE_LIBRARY=ON
    fi
fi

if hasArg bench-prims; then
    BUILD_PRIMS_BENCH=ON
    CMAKE_TARGET="${CMAKE_TARGET};${PRIMS_BENCH_TARGETS}"

    # Force compile library when needed benchmark targets are specified
    if [[ $CMAKE_TARGET == *"CLUSTER_PRIMS_BENCH"* || \
          $CMAKE_TARGET == *"MATRIX_PRIMS_BENCH"* || \
          $CMAKE_TARGET == *"NEIGHBORS_PRIMS_BENCH"* ]]; then
      echo "-- Enabling compiled lib for benchmarks"
      COMPILE_LIBRARY=ON
    fi
fi

if hasArg bench-ann || (( ${NUMARGS} == 0 )); then
    BUILD_ANN_BENCH=ON
    CMAKE_TARGET="${CMAKE_TARGET};${ANN_BENCH_TARGETS}"
    if hasArg --cpu-only; then
        COMPILE_LIBRARY=OFF
        BUILD_CPU_ONLY=ON
        NVTX=OFF
    else
        COMPILE_LIBRARY=ON
    fi
fi

if hasArg --no-nvtx; then
    NVTX=OFF
fi
if hasArg --time; then
    echo "-- Logging compile times to cpp/build/nvcc_compile_log.csv"
    LOG_COMPILE_TIME=ON
fi
if hasArg --show_depr_warn; then
    DISABLE_DEPRECATION_WARNINGS=OFF
fi
if hasArg clean; then
    CLEAN=1
fi
if hasArg --incl-cache-stats; then
    BUILD_REPORT_INCL_CACHE_STATS=ON
fi
if [[ ${CMAKE_TARGET} == "" ]]; then
    CMAKE_TARGET="all"
fi

# Replace spaces with semicolons in SKBUILD_EXTRA_CMAKE_ARGS
SKBUILD_EXTRA_CMAKE_ARGS=$(echo ${EXTRA_CMAKE_ARGS} | sed 's/ /;/g')

# If clean given, run it prior to any other steps
if (( ${CLEAN} == 1 )); then
    # If the dirs to clean are mounted dirs in a container, the
    # contents should be removed but the mounted dirs will remain.
    # The find removes all contents but leaves the dirs, the rmdir
    # attempts to remove the dirs but can fail safely.
    for bd in ${BUILD_DIRS}; do
      if [ -d ${bd} ]; then
          find ${bd} -mindepth 1 -delete
          rmdir ${bd} || true
      fi
    done
fi

################################################################################
# Configure for building all C++ targets
if (( ${NUMARGS} == 0 )) || hasArg libraft || hasArg tests || hasArg bench-prims || hasArg package; then
    if (( ${BUILD_ALL_GPU_ARCH} == 0 )); then
        HIPRAFT_CMAKE_HIP_ARCHITECTURES="${HIPRAFT_CMAKE_HIP_ARCHITECTURES:-NATIVE}"
        if [[ "$HIPRAFT_CMAKE_HIP_ARCHITECTURES" == "NATIVE" ]]; then
            echo "Building for the architecture of the GPU in the system..."
        else
            echo "Building for the GPU architecture(s) $HIPRAFT_CMAKE_HIP_ARCHITECTURES ..."
        fi
    else
        HIPRAFT_CMAKE_HIP_ARCHITECTURES="RAPIDS"
        echo "Building for *ALL* supported GPU architectures..."
    fi

    # get the current count before the compile starts
    CACHE_TOOL=${CACHE_TOOL:-sccache}
    if [[ "$BUILD_REPORT_INCL_CACHE_STATS" == "ON" && -x "$(command -v ${CACHE_TOOL})" ]]; then
        "${CACHE_TOOL}" --zero-stats
    fi

    mkdir -p ${LIBRAFT_BUILD_DIR}
    cd ${LIBRAFT_BUILD_DIR}
    cmake -S ${REPODIR}/cpp -B ${LIBRAFT_BUILD_DIR} \
          -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
          -DCMAKE_HIP_ARCHITECTURES=${HIPRAFT_CMAKE_HIP_ARCHITECTURES} \
          -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
          -DRAFT_COMPILE_LIBRARY=${COMPILE_LIBRARY} \
          -DDISABLE_DEPRECATION_WARNINGS=${DISABLE_DEPRECATION_WARNINGS} \
          -DBUILD_TESTS=${BUILD_TESTS} \
          -DBUILD_PRIMS_BENCH=${BUILD_PRIMS_BENCH} \
          -DCMAKE_MESSAGE_LOG_LEVEL=${CMAKE_LOG_LEVEL} \
          ${EXTRA_CMAKE_HIP_ARGS} \
          ${CACHE_ARGS} \
          ${EXTRA_CMAKE_ARGS}


  compile_start=$(date +%s)
  if [[ ${CMAKE_TARGET} != "" ]]; then
      echo "-- Compiling targets: ${CMAKE_TARGET}, verbose=${VERBOSE_FLAG}"
      if [[ ${INSTALL_TARGET} != "" ]]; then
        cmake --build  "${LIBRAFT_BUILD_DIR}" ${VERBOSE_FLAG} -j${PARALLEL_LEVEL} --target ${CMAKE_TARGET} ${INSTALL_TARGET}
      else
        cmake --build  "${LIBRAFT_BUILD_DIR}" ${VERBOSE_FLAG} -j${PARALLEL_LEVEL} --target ${CMAKE_TARGET}
      fi
  fi
  compile_end=$(date +%s)
  compile_total=$(( compile_end - compile_start ))

  if [[ -n "$BUILD_REPORT_METRICS" && -f "${LIBRAFT_BUILD_DIR}/.ninja_log" ]]; then
      if ! rapids-build-metrics-reporter.py 2> /dev/null && [ ! -f rapids-build-metrics-reporter.py ]; then
          echo "Downloading rapids-build-metrics-reporter.py"
          curl -sO https://raw.githubusercontent.com/rapidsai/build-metrics-reporter/v1/rapids-build-metrics-reporter.py
      fi

      echo "Formatting build metrics"
      MSG=""
      # get some sccache/ccache stats after the compile
      if [[ "$BUILD_REPORT_INCL_CACHE_STATS" == "ON" ]]; then
          if [[ ${CACHE_TOOL} == "sccache" && -x "$(command -v sccache)" ]]; then
              COMPILE_REQUESTS=$(sccache -s | grep "Compile requests \+ [0-9]\+$" | awk '{ print $NF }')
              CACHE_HITS=$(sccache -s | grep "Cache hits \+ [0-9]\+$" | awk '{ print $NF }')
              HIT_RATE=$(COMPILE_REQUESTS="${COMPILE_REQUESTS}" CACHE_HITS="${CACHE_HITS}" python3 -c "import os; print(f'{int(os.getenv(\"CACHE_HITS\")) / int(os.getenv(\"COMPILE_REQUESTS\")):.2f}' if int(os.getenv(\"COMPILE_REQUESTS\")) else 'nan')")
              MSG="${MSG}<br/>cache hit rate ${HIT_RATE} %"
          elif [[ ${CACHE_TOOL} == "ccache" && -x "$(command -v ccache)" ]]; then
              CACHE_STATS_LINE=$(ccache -s | grep "Hits: \+ [0-9]\+ / [0-9]\+" | tail -n1)
              if [[ ! -z "$CACHE_STATS_LINE" ]]; then
                  CACHE_HITS=$(echo "$CACHE_STATS_LINE" - | awk '{ print $2 }')
                  COMPILE_REQUESTS=$(echo "$CACHE_STATS_LINE" - | awk '{ print $4 }')
                  HIT_RATE=$(COMPILE_REQUESTS="${COMPILE_REQUESTS}" CACHE_HITS="${CACHE_HITS}" python3 -c "import os; print(f'{int(os.getenv(\"CACHE_HITS\")) / int(os.getenv(\"COMPILE_REQUESTS\")):.2f}' if int(os.getenv(\"COMPILE_REQUESTS\")) else 'nan')")
                  MSG="${MSG}<br/>cache hit rate ${HIT_RATE} %"
              fi
          fi
      fi
      MSG="${MSG}<br/>parallel setting: $PARALLEL_LEVEL"
      MSG="${MSG}<br/>parallel build time: $compile_total seconds"
      if [[ -f "${LIBRAFT_BUILD_DIR}/libraft.so" ]]; then
          LIBRAFT_FS=$(ls -lh ${LIBRAFT_BUILD_DIR}/libraft.so | awk '{print $5}')
          MSG="${MSG}<br/>libraft.so size: $LIBRAFT_FS"
      fi
      BMR_DIR=${RAPIDS_ARTIFACTS_DIR:-"${LIBRAFT_BUILD_DIR}"}
      echo "The HTML report can be found at [${BMR_DIR}/${BUILD_REPORT_METRICS}.html]. In CI, this report"
      echo "will also be uploaded to the appropriate subdirectory of https://downloads.rapids.ai/ci/raft/, and"
      echo "the entire URL can be found in \"conda-cpp-build\" runs under the task \"Upload additional artifacts\""
      mkdir -p ${BMR_DIR}
      MSG_OUTFILE="$(mktemp)"
      echo "$MSG" > "${MSG_OUTFILE}"
      PATH=".:$PATH" python rapids-build-metrics-reporter.py ${LIBRAFT_BUILD_DIR}/.ninja_log --fmt html --msg "${MSG_OUTFILE}" > ${BMR_DIR}/${BUILD_REPORT_METRICS}.html
      cp ${LIBRAFT_BUILD_DIR}/.ninja_log ${BMR_DIR}/ninja.log
  fi
fi

# Build and (optionally) install the pylibraft Python package
if (( ${NUMARGS} == 0 )) || hasArg pylibraft; then
    # Build and install libraft pip package
    SKBUILD_CMAKE_ARGS="-DCMAKE_CXX_COMPILER=hipcc;-DCMAKE_PREFIX_PATH=${INSTALL_PREFIX};${EXTRA_CMAKE_ARGS}" \
        python -m pip install --no-build-isolation ${REPODIR}/python/libraft
    # Build and install pylibraft pip package
    SKBUILD_CMAKE_ARGS="-DCMAKE_CXX_COMPILER=hipcc;-DCMAKE_PREFIX_PATH=${INSTALL_PREFIX};${EXTRA_CMAKE_ARGS}" \
        python -m pip install --no-build-isolation ${REPODIR}/python/pylibraft
fi

# Build and (optionally) install the raft-dask Python package
if (( ${NUMARGS} == 0 )) || hasArg raft-dask; then
    SKBUILD_CMAKE_ARGS="${SKBUILD_EXTRA_CMAKE_ARGS}" \
        python -m pip install --no-build-isolation --no-deps --config-settings rapidsai.disable-cuda=true ${REPODIR}/python/raft-dask
fi

if hasArg docs; then
    set -x
    export RAPIDS_VERSION="$(sed -E -e 's/^([0-9]{2})\.([0-9]{2})\.([0-9]{2}).*$/\1.\2.\3/' "${REPODIR}/VERSION")"
    export RAPIDS_VERSION_MAJOR_MINOR="$(sed -E -e 's/^([0-9]{2})\.([0-9]{2})\.([0-9]{2}).*$/\1.\2/' "${REPODIR}/VERSION")"
    cd ${SPHINX_BUILD_DIR}
    mkdir -p _build
    rm -rf _build/*
    LC_ALL=C.UTF-8 sphinx-build -E . _build
fi

if hasArg examples; then
    set -x
    CMAKE_OVERRIDES_FILE="`readlink -f overrides.cmake`"

    PARALLEL_LEVEL=${PARALLEL_LEVEL} \
    BUILD_TYPE=${BUILD_TYPE} \
    BUILD_DIR=${EXAMPLES_BUILD_DIR} \
    RAFT_REPO_REL=${REPODIR} \
    EXTRA_CMAKE_ARGS="-DCMAKE_USER_MAKE_RULES_OVERRIDE=${CMAKE_OVERRIDES_FILE}" \
    bash ${REPODIR}/examples/build.sh
fi

#! /usr/bin/env bash

# MIT License
#
# Copyright (c) 2025 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#-------------------------------------------------------------------------------------------------
# This script runs the C++ tests to collect code coverage data and generates an HTML report using
# `llvm-profdata` and `llvm-cov`. To enable code coverage instrumentation, build with the CMake
# option `ENABLE_CODE_COVERAGE=ON`. Run this script from inside the build directory, or set the
# environment variable `HIPRAFT_BUILD_DIR` to point to the build directory. The generated profile
# data will be located under `${HIPRAFT_BUILD_DIR}/profiles`, and the HTML report will be saved to
# `${HIPRAFT_BUILD_DIR}/coverage_report`.
#-------------------------------------------------------------------------------------------------


set -e

HIPRAFT_BUILD_DIR=${HIPRAFT_BUILD_DIR:="${PWD}"}
HIPRAFT_PROFILES_DIR=${HIPRAFT_BUILD_DIR}/profiles
HIPRAFT_COVERAGE_DATA=${HIPRAFT_BUILD_DIR}/hipraft-coverage.profdata
HIPRAFT_COVERAGE_REPORT_PATH=${HIPRAFT_BUILD_DIR}/coverage_report

mkdir -p $HIPRAFT_PROFILES_DIR

# Run C++ tests
BINARIES=("${HIPRAFT_BUILD_DIR}/libraft.so")
GTEST_DIR="${HIPRAFT_BUILD_DIR}/gtests"
if [ -d "${GTEST_DIR}" ]; then
    cd "${GTEST_DIR}"
    for test_exec in *; do
        if [[ -x "$test_exec" ]]; then
            echo "Running ./${test_exec} ..."
            BINARIES+=("${GTEST_DIR}/${test_exec}")
            export LLVM_PROFILE_FILE="${HIPRAFT_PROFILES_DIR}/${test_exec}.profraw"
            if ! ./$test_exec; then
                echo "Test ${test_exec} failed"
                have_failures=1
            fi
        else
            echo "Skipping non-executable file: ${test_exec}"
        fi
    done
else
    echo "C++ test directory not found at ${GTEST_DIR}"
    have_failures=1
fi

set -x

llvm-profdata merge -sparse ${HIPRAFT_PROFILES_DIR}/*.profraw -o ${HIPRAFT_COVERAGE_DATA}

mkdir -p $HIPRAFT_COVERAGE_REPORT_PATH

OBJECTS="$(printf ' --object=%s' "${BINARIES[@]}")"
LLVM_COV_OPTIONS="--format=html --show-line-counts-or-regions --Xdemangler c++filt"
llvm-cov show \
    ${OBJECTS} ${LLVM_COV_OPTIONS} \
    --instr-profile=${HIPRAFT_COVERAGE_DATA} \
    --output-dir=${HIPRAFT_COVERAGE_REPORT_PATH} \
    --ignore-filename-regex=${HIPRAFT_BUILD_DIR}/_deps

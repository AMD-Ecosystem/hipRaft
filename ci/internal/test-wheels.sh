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

# Test hipRAFT wheels in an isolated venv, using the interpreter on PATH.
#
# Required environment variables:
#   PROJECT_ID, BUILD_DIR, BUILD_ARTIFACTS_DIR, ARTIFACTS_DIR
#
# Optional environment variables:
#   HIPRAFT_TEST_RESULTS_SUFFIX -- appended to the pytest output dir and the
#               results CSV name. test-wheels-manylinux.sh sets it per
#               interpreter, since the passes share this checkout and this
#               artifacts dir; unset, the names are the ones test-py.sh
#               also writes.
#   HIPRAFT_VERSION -- pins the hipRAFT wheels installed from BUILD_ARTIFACTS_DIR
#   HIPBLASLT_TENSILE_LIBPATH -- where hipBLASLt looks for its Tensile kernels.
#               Left alone when set; otherwise auto-detected, see
#               setup_hipblaslt_tensile_libpath in _rocm-workarounds.sh.

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${PROJECT_ID:?PROJECT_ID must be set}"
: "${BUILD_DIR:?BUILD_DIR must be set}"
: "${BUILD_ARTIFACTS_DIR:?BUILD_ARTIFACTS_DIR must be set}"
: "${ARTIFACTS_DIR:?ARTIFACTS_DIR must be set}"

source "${SCRIPT_DIR}/_test-helpers.sh"
source "${SCRIPT_DIR}/_wheel-helpers.sh"
source "${SCRIPT_DIR}/_rocm-workarounds.sh"

wheels_test_env=$(mktemp -d)
python3 -m venv "${wheels_test_env}"
. "${wheels_test_env}/bin/activate"

  pip install --upgrade pip
  . "${SCRIPT_DIR}/_install-test-deps.sh"

  # No --no-index here, unlike the build: this install resolves the wheels'
  # own runtime dependencies for real.
  #
  # NOTE(HIP/AMD): amd_raft_dask is opt-in via HIPRAFT_ENABLE_RAFT_DASK (the same
  # central toggle build-wheels-manylinux.sh gates its build on). Install and
  # test it only when that build was enabled; otherwise the wheel does not exist.
  wheel_specs=(
    "amd_libraft${HIPRAFT_VERSION:+==${HIPRAFT_VERSION}}"
    "amd_pylibraft${HIPRAFT_VERSION:+==${HIPRAFT_VERSION}}"
  )
  [ "${HIPRAFT_ENABLE_RAFT_DASK:-false}" = "true" ] && \
    wheel_specs+=( "amd_raft_dask${HIPRAFT_VERSION:+==${HIPRAFT_VERSION}}" )
  install_built_wheel -- "${wheel_specs[@]}"

  setup_hipblaslt_tensile_libpath

  test_failures=0
  cd "${BUILD_DIR}/${PROJECT_ID}"

      results_suffix=${HIPRAFT_TEST_RESULTS_SUFFIX:+-${HIPRAFT_TEST_RESULTS_SUFFIX}}
      CSV_OUTPUT_DIR=${PROJECT_ID}_pytest_output${results_suffix}

      TIMEOUT_PER_TEST_SEC=240

      run_tests python/pylibraft/pylibraft/tests "${CSV_OUTPUT_DIR}" "${TIMEOUT_PER_TEST_SEC}"
      if [ "${HIPRAFT_ENABLE_RAFT_DASK:-false}" = "true" ]; then
        run_tests python/raft-dask/raft_dask/tests "${CSV_OUTPUT_DIR}" "${TIMEOUT_PER_TEST_SEC}"
      fi

      result=$(merge_test_results "${CSV_OUTPUT_DIR}") || test_failures=1
      echo "$result" > "${ARTIFACTS_DIR}/${PROJECT_ID}-test-results-py${results_suffix}.csv"

deactivate
rm -rf "${wheels_test_env}"

exit "$test_failures"

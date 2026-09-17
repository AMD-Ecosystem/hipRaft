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

# Run the hipRAFT Python tests via pytest, against the Python components the
# dev build installed into the conda env or the dev venv. The wheel equivalent
# is test-wheels.sh, which installs from BUILD_ARTIFACTS_DIR instead.
#
# Required environment variables:
#   PROJECT_ID, BUILD_DIR, INSTALL_DIR, ARTIFACTS_DIR, BUILD_ARTIFACTS_DIR
#
# Optional environment variables:
#   HIPRAFT_CONDA_ENV, CONDA_DIR -- for conda-based environments
#   CMAKE_INSTALL_PREFIX         -- overrides INSTALL_DIR as the prefix the
#                                   venv-mode LD_LIBRARY_PATH points at
#   HIPBLASLT_TENSILE_LIBPATH    -- where hipBLASLt looks for its Tensile
#                                   kernels. Left alone when set; otherwise
#                                   auto-detected, see
#                                   setup_hipblaslt_tensile_libpath in
#                                   _rocm-workarounds.sh.

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_activate-env.sh"
source "${SCRIPT_DIR}/_test-helpers.sh"
source "${SCRIPT_DIR}/_rocm-workarounds.sh"
require_envs PROJECT_ID BUILD_DIR INSTALL_DIR ARTIFACTS_DIR BUILD_ARTIFACTS_DIR

printenv

# Prefer the conda env (HIPRAFT_CONDA_ENV) when set; otherwise use the venv.
# note: the test phase might run without the preceding build phase.
if ! activate_hipraft_conda_env; then
    activate_hipraft_venv
    install_prefix="${CMAKE_INSTALL_PREFIX:-${INSTALL_DIR}}"
    export LD_LIBRARY_PATH="\
${install_prefix}/lib:\
${install_prefix}/lib64:\
${LD_LIBRARY_PATH:-}"
fi

# Activation can set ROCM_PATH, so this has to come after it.
setup_hipblaslt_tensile_libpath

. "${SCRIPT_DIR}/_install-test-deps.sh"

test_failures=0
cd "${BUILD_DIR}/${PROJECT_ID}"

    CSV_OUTPUT_DIR=${PROJECT_ID}_pytest_output

    TIMEOUT_PER_TEST_SEC=240

    run_tests python/pylibraft/pylibraft/tests "${CSV_OUTPUT_DIR}" "${TIMEOUT_PER_TEST_SEC}"

    result=$(merge_test_results "${CSV_OUTPUT_DIR}") || test_failures=1
    echo "$result" > "${ARTIFACTS_DIR}/${PROJECT_ID}-test-results-py.csv"

exit "$test_failures"

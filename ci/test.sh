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

# Run hipRAFT test suites based on environment variables.
#
# Required environment variables:
#   PROJECT_ID, BUILD_DIR
#
# Optional environment variables (each defaults to false):
#   HIPRAFT_CPP_TESTS      -- run C++ tests via ctest
#   HIPRAFT_PYTHON_TESTS   -- run Python tests via pytest
#   HIPRAFT_RUN_BENCH_PRIMS -- run primitives benchmarks
#   HIPRAFT_RUN_EXAMPLES   -- run C++ examples

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"
require_envs PROJECT_ID BUILD_DIR INSTALL_DIR

printenv

# Prefer the conda env (HIPRAFT_CONDA_ENV) when set; otherwise use the venv.
# note: the test phase might run without the preceding build phase.
if ! activate_hipraft_conda_env; then
    activate_hipraft_venv
fi

exit_code=0

if [[ "${HIPRAFT_CPP_TESTS:-false}" == "true" ]]; then
    echo "=== Running C++ tests ==="
    (cd "${BUILD_DIR}/${PROJECT_ID}/cpp/build/tests" && ctest --output-on-failure .) || exit_code=$?
fi

if [[ "${HIPRAFT_PYTHON_TESTS:-false}" == "true" ]]; then
    echo "=== Running Python tests ==="
    pip install scikit-learn
    (cd "${BUILD_DIR}/${PROJECT_ID}" && pytest -v --continue-on-collection-errors python/pylibraft/pylibraft/tests) || exit_code=$?
fi

if [[ "${HIPRAFT_RUN_BENCH_PRIMS:-false}" == "true" ]]; then
    echo "=== Running bench prims ==="
    (cd "${BUILD_DIR}/${PROJECT_ID}/cpp/build/bench/prims" && find . -maxdepth 1 -not -name "*.so*" -type f -executable -exec {} \;) || exit_code=$?
fi

if [[ "${HIPRAFT_RUN_EXAMPLES:-false}" == "true" ]]; then
    echo "=== Running examples ==="
    (cd "${BUILD_DIR}/${PROJECT_ID}/examples/build" && find . -maxdepth 1 -not -name "*.so*" -type f -executable -exec {} \;) || exit_code=$?
fi

exit "${exit_code}"

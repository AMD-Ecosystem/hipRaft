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

# Run the hipRAFT C++ test suite via ctest, and optionally the C++ examples.
#
# Interpreter-independent, so the manylinux tester runs this once beside the
# per-interpreter wheel matrix.
#
# Required environment variables:
#   PROJECT_ID, BUILD_DIR, INSTALL_DIR
#
# Optional environment variables:
#   ENABLE_BENCHMARKS -- 1/true/yes/on runs report-only benchmarks instead of tests
#   HIPRAFT_RUN_EXAMPLES -- also run the built C++ examples (default: false)
#   HIPRAFT_CONDA_ENV, CONDA_DIR -- for conda-based environments
#   HIPBLASLT_TENSILE_LIBPATH -- where hipBLASLt looks for its Tensile kernels.
#               Left alone when set; otherwise auto-detected, see
#               setup_hipblaslt_tensile_libpath in _rocm-workarounds.sh.

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The tester wrapper always calls this entry point once. Dispatch before test
# setup so benchmark jobs need neither CTest nor coverage artifacts.
case "${ENABLE_BENCHMARKS:-false}" in
    1 | true | yes | on)
        echo "=== Benchmarks only (C++ tests disabled; report-only) ==="
        if ! bash "${SCRIPT_DIR}/benchmark-cpp.sh"; then
            echo "WARNING: benchmarks failed; see ${ARTIFACTS_DIR:-/artifacts}/benchmarks (report-only)"
        fi
        exit 0
        ;;
esac

source "${SCRIPT_DIR}/_activate-env.sh"
source "${SCRIPT_DIR}/_rocm-workarounds.sh"
source "${SCRIPT_DIR}/_test-helpers.sh"
require_envs PROJECT_ID BUILD_DIR INSTALL_DIR
: "${ARTIFACTS_DIR:=/artifacts}"

printenv

# Prefer the conda env (HIPRAFT_CONDA_ENV) when set; otherwise use the venv.
# note: the test phase might run without the preceding build phase.
if ! activate_hipraft_conda_env; then
    activate_hipraft_venv
fi

# Activation can set ROCM_PATH, so this has to come after it.
setup_hipblaslt_tensile_libpath

exit_code=0

cpp_build="${BUILD_DIR}/${PROJECT_ID}/cpp/build"
begin_llvm_profiling "${cpp_build}/profiles"

echo "=== Running C++ tests ==="
(cd "${cpp_build}/tests" && ctest --output-on-failure .) || exit_code=$?

llvm_objects=()
[[ -e "${cpp_build}/libraft.so" ]] && llvm_objects+=("${cpp_build}/libraft.so")
shopt -s nullglob
llvm_objects+=("${cpp_build}/gtests"/*)
shopt -u nullglob
export_llvm_cov_json "${cpp_build}/profiles" \
    "${COVERAGE_LLVM_JSON:-${ARTIFACTS_DIR}/llvm-cov_code_coverage.json}" \
    "${llvm_objects[@]}"

if [[ "${HIPRAFT_RUN_EXAMPLES:-false}" == "true" ]]; then
    echo "=== Running examples ==="
    (cd "${BUILD_DIR}/${PROJECT_ID}/examples/build" && find . -maxdepth 1 -not -name "*.so*" -type f -executable -exec {} \;) || exit_code=$?
fi

exit "${exit_code}"

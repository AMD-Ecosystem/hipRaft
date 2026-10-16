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

# Run the hipRAFT primitives benchmarks build-dev.sh built.
#
# Required environment variables:
#   PROJECT_ID, BUILD_DIR, INSTALL_DIR
#
# Optional environment variables:
#   HIPRAFT_CONDA_ENV, CONDA_DIR -- for conda-based environments
#   ARTIFACTS_DIR -- result root (default: /artifacts)

set -euxo pipefail

results_dir="${ARTIFACTS_DIR:-/artifacts}/benchmarks"
mkdir -p "${results_dir}"
results_dir="$(cd "${results_dir}" && pwd)"
exec > >(tee "${results_dir}/runner.log") 2>&1
trap 'echo "ERROR: benchmark runner failed at line ${LINENO}" >&2' ERR
printf 'executable,exit_code,report_status\n' > "${results_dir}/status.csv"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_activate-env.sh"
require_envs PROJECT_ID BUILD_DIR INSTALL_DIR

# Prefer the conda env (HIPRAFT_CONDA_ENV) when set; otherwise use the venv.
# note: the benchmark phase might run without the preceding build phase.
if ! activate_hipraft_conda_env; then
    activate_hipraft_venv
fi

echo "=== Running bench prims ==="
cd "${BUILD_DIR}/${PROJECT_ID}/cpp/build/bench/prims"
failed=0
count=0
shopt -s nullglob
for executable in ./*; do
    [[ -f "${executable}" && -x "${executable}" && "${executable}" != *.so* ]] || continue
    name="${executable#./}"
    count=$((count + 1))
    report="${results_dir}/${name}.json"
    # Truncate any earlier report so a failed rerun cannot look successful.
    : > "${report}"
    rc=0
    if "${executable}" --benchmark_out="${report}" --benchmark_out_format=json \
        2>&1 | tee "${results_dir}/${name}.log"; then
        :
    else
        statuses=("${PIPESTATUS[@]}")
        rc="${statuses[0]}"
        [[ "${rc}" -ne 0 ]] || rc="${statuses[1]}"
    fi
    report_status=present
    if [[ ! -s "${report}" ]]; then
        report_status=missing_or_empty
        failed=1
    fi
    [[ "${rc}" -eq 0 ]] || failed=1
    csv_name="${name//\"/\"\"}"
    printf '"%s",%s,%s\n' "${csv_name}" "${rc}" "${report_status}" >> "${results_dir}/status.csv"
done
if [[ "${count}" -eq 0 ]]; then
    echo "ERROR: no benchmark executables found in ${PWD}" >&2
    failed=1
fi
exit "${failed}"

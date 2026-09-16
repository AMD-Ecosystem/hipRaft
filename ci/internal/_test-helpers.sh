# shellcheck shell=bash
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

# Shared test helper functions for hipRAFT CI.
# Meant to be sourced, not executed directly.
#
# Provides:
#   run_tests()          -- runs pytest per test file with CSV output and timeout
#   merge_test_results() -- merges per-file CSV results into a single file
#
# Prerequisites: pytest, pytest-csv, pytest-timeout must be installed.

set -euo pipefail

# Runs all test files under a folder individually, each with its own timeout and
# CSV output, so one hanging or crashing test cannot take the rest down with it.
#
# Arguments:
#   1 (required) input folder to search for test_*.py
#   2 (required) output folder for the per-file CSV results
#   3 (required) per-test timeout in seconds: long enough for the slow tests to
#                finish, short enough to abort a hanging one
#   4 (optional) extra pytest arguments; quote them if there is more than one
#   5 (optional) suffix appended to the CSV filename
#   6 (optional) suffix appended to the test ID in the CSV output
#
# 4-6 are defaulted below, so a caller that passes only the required three does
# not trip `set -u` on the unset positionals.
function run_tests() {
    set +e # continue on error
    local test_dir=$1
    local output_dir=$2
    local timeout=$3
    local extra_args=${4:-""}
    local suffix=${5:-""}
    local id_suffix=${6:-""}
    find "$test_dir" -name "test_*.py" \
      -printf "run_tests: found test file: %p\n" \
      -exec bash -c '
        csv_file="$2/$7${5}.csv"
        pytest $4 -v --timeout $3 "$7" \
        --continue-on-collection-errors \
        --csv "$csv_file" --csv-columns file,id,status,message
        if [[ -n "$5" && -f "$csv_file" ]]; then
          temp_file=$(mktemp)
          head -n 1 "$csv_file" > "$temp_file"
          tail -n +2 "$csv_file" | awk -F"," -v suffix="$6" "BEGIN{OFS=\",\"} {\$2=\$2 suffix; print}" >> "$temp_file"
          mv "$temp_file" "$csv_file"
        fi
        ' _ "$test_dir" "$output_dir" "$timeout" "$extra_args" "$suffix" "$id_suffix" {} \;
    set -e
}


# Merges all per-file results in a folder (1st arg) into a single CSV.
# NOTE: We currently group the tests such that all files with zero failures
#       come first. To have a more deterministic order, we might consider to
#       change that behavior.
function merge_test_results() {
    # note: status emitted by pytest-csv: passed, failed, error, skipped,
    #       xpassed, xfailed
    # note: status is second last CSV column, so is embedded within ","
    FAILURE_EXPR=",\(error\|failed\),"

    result=""
    test_failures=0
    # first add results with no 'failed' or 'error' status (xfailed are included)
    i=0
    while IFS= read -r f; do
        if (( i == 0 )); then
            result+=$(cat "$f")
        else
            result+=$(tail -n +2 "$f")
        fi
        i=1
    done < <(grep -rL "${FAILURE_EXPR}" --include="*.csv" "$1")
    # second include results with failed
    while IFS= read -r f; do
        test_failures=1
        if (( i == 0 )); then
            result+=$(cat "$f")
        else
            result+=$(tail -n +2 "$f")
        fi
        i=1
    done < <(grep -rl "${FAILURE_EXPR}" --include="*.csv" "$1")
    echo "$result"
    return $test_failures
}

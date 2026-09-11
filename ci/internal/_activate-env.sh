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

# Shared helpers: environment validation and build-environment activation.
# Meant to be sourced, not executed directly.
#
# Provides:
#   require_envs()                 - fails with a clear error if any named
#                                    variable is unset or empty
#   activate_hipraft_venv()        - activates the dev venv build-dev.sh creates
#   activate_hipraft_conda_env()   - activates HIPRAFT_CONDA_ENV when set

set -euo pipefail

require_envs() {
    local missing=0
    for var in "$@"; do
        if [ -z "${!var:-}" ]; then
            echo "ERROR: required environment variable ${var} is not set." >&2
            missing=1
        fi
    done
    if [ "$missing" -ne 0 ]; then
        echo "ERROR: missing required environment variables (see above). Aborting." >&2
        exit 1
    fi
}


activate_hipraft_venv() {
    . "${INSTALL_DIR}/venv/hipraft_dev/bin/activate"
}


# Activates the conda env named by HIPRAFT_CONDA_ENV, if set.
#
# Returns 0 (and activates the env) when HIPRAFT_CONDA_ENV is set, 1 otherwise so
# callers can fall back to activate_hipraft_venv.
#
# Required environment variables (when HIPRAFT_CONDA_ENV is set):
#   HIPRAFT_CONDA_ENV -- name of the conda environment to activate
#   CONDA_DIR         -- path to the conda installation
activate_hipraft_conda_env() {
    if [ -n "${HIPRAFT_CONDA_ENV:-}" ]; then
        set +u # note: conda script may have unbound variables
        source "${CONDA_DIR}/etc/profile.d/conda.sh"
        conda activate "${HIPRAFT_CONDA_ENV}"
        set -u

        # Add the conda env lib directory to LD_LIBRARY_PATH so Python extensions
        # and tests can find shared libs (librmm.so, libraft.so) that are installed
        # into the conda env's lib directory rather than next to the .so consumers.
        export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
        return 0
    fi
    return 1
}

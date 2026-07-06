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
#
# Regenerate pybind11-stubgen type stubs for the amd-pylibraft (hipRAFT) Python
# package. The generated ``.pyi`` stubs are consumed by sphinx-autoapi to build
# the Python API reference in environments where amd-pylibraft is unavailable.
#
# Usage: ./generate_stubs.sh
#
# Prerequisites: a Python environment with both `pylibraft` and
# `pybind11-stubgen` installed. The script will exit early if either is missing.
# The checked-in stubs are auto-generated, so this only needs to be re-run when
# the pylibraft API changes. The repo's amd-copyright pre-commit hook injects
# the MIT license header into each generated .pyi at commit time, so this script
# does not add it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUBS_DIR="$SCRIPT_DIR/stubs/pylibraft"

python -c "import pylibraft" 2>/dev/null || { echo "Error: pylibraft is not installed in the current Python environment." >&2; exit 1; }
command -v pybind11-stubgen >/dev/null 2>&1 || { echo "Error: pybind11-stubgen is not installed. Install with: pip install pybind11-stubgen" >&2; exit 1; }

# pylibraft's public submodules are compiled Cython (.abi3.so) extensions that
# `pkgutil.walk_packages` does not reliably recurse into, so the set of modules
# consumed by the Python API reference is enumerated explicitly here. Add a new
# entry (and a matching autoapi directive in the *.rst pages) when the public API
# grows.
MODULES=(
    pylibraft
    pylibraft._version
    pylibraft.common
    pylibraft.common.cai_wrapper
    pylibraft.common.cuda
    pylibraft.common.device_ndarray
    pylibraft.common.handle
    pylibraft.common.input_validation
    pylibraft.common.interruptible
    pylibraft.common.outputs
    pylibraft.random
    pylibraft.random.rmat_rectangular_generator
    pylibraft.sparse.linalg
    pylibraft.sparse.linalg.lanczos
)

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Generating stubs into $TMPDIR ..."
for mod in "${MODULES[@]}"; do
    echo "  $mod"
    pybind11-stubgen --ignore-all-errors -o "$TMPDIR" "$mod" 2>/dev/null || true
done

GENERATED=$(find "$TMPDIR/pylibraft" -name "*.pyi" 2>/dev/null | wc -l)
if [ "$GENERATED" -eq 0 ]; then
    echo "Error: no stub files were generated." >&2
    exit 1
fi

echo "Replacing $STUBS_DIR ..."
rm -rf "$STUBS_DIR"
cp -r "$TMPDIR/pylibraft" "$STUBS_DIR"

echo "Done. Generated $GENERATED stub files."
echo "Note: run pre-commit (amd-copyright) to add license headers before committing."

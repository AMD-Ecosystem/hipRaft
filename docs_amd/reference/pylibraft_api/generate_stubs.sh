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
# the pylibraft API changes. `.pre-commit-config.yaml` excludes this stubs tree
# from every hook (including amd-copyright), so the license header is injected
# here instead.
#
# Each stub is a derived work -- most of its content is docstring text copied
# verbatim out of the corresponding pylibraft source -- so each stub carries the
# same copyright notices as the file it was generated from, years included. The
# notices are read back out of that source rather than hardcoded here, so they
# never drift and never need an annual bump: bumping NVIDIA's years because we
# re-ran a generator would be asserting authorship we do not have, and AMD's
# modifications notice belongs only on the stubs whose source actually carries
# one.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUBS_DIR="$SCRIPT_DIR/stubs/pylibraft"
SRC_DIR="$SCRIPT_DIR/../../../python/pylibraft/pylibraft"

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
    pylibraft.sparse.linalg.svds
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

# Locate the pylibraft source a stub was generated from, e.g.
# `<tmp>/pylibraft/common/cuda.pyi` -> `$SRC_DIR/common/cuda.pyx`.
stub_source() {
    local rel="${1#"$TMPDIR/pylibraft/"}"
    rel="${rel%.pyi}"
    for ext in py pyx; do
        [ -f "$SRC_DIR/$rel.$ext" ] && { echo "$SRC_DIR/$rel.$ext"; return 0; }
    done
    return 1
}

# Emit the header for a stub generated from source $1: the upstream NVIDIA
# notice re-emitted verbatim (so the years always match the source the docstrings
# were copied from), followed by AMD's modifications notice.
#
# The AMD block is emitted unconditionally even when the source carries no AMD
# notice. The amd-copyright pre-commit hook runs with `pass_filenames: false`, so
# license_verificator does its own git-based file discovery and ignores the
# `docs_amd/reference/.*/stubs/` exclude in .pre-commit-config.yaml -- it will
# append this block to any stub that lacks it. Emitting it here keeps
# regeneration idempotent instead of leaving the hook to rewrite every stub.
stub_header() {
    local src="$1"
    grep -m1 -E '^# SPDX-FileCopyrightText:.*NVIDIA' "$src"
    grep -m1 -E '^# SPDX-License-Identifier:' "$src"
    echo '#'
    echo
    echo '# MIT License'
    echo '#'
    # Reuse the source's own AMD notice when it has one, so its year range is
    # preserved; otherwise claim only the year this stub was generated.
    grep -m1 -E '^# .*Copyright \(C\).*Advanced Micro Devices' "$src" \
        || echo "# Modifications Copyright (C) $(date +%Y) Advanced Micro Devices, Inc. All rights reserved."
    cat <<'EOF'
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
EOF
    echo
}

echo "Prepending license headers ..."
while IFS= read -r -d '' stub; do
    src=$(stub_source "$stub") || { echo "Error: no pylibraft source found for stub ${stub#"$TMPDIR/"}; cannot determine its copyright notice." >&2; exit 1; }
    { stub_header "$src"; cat "$stub"; } > "$stub.licensed"
    mv "$stub.licensed" "$stub"
done < <(find "$TMPDIR/pylibraft" -name "*.pyi" -print0)

echo "Replacing $STUBS_DIR ..."
rm -rf "$STUBS_DIR"
cp -r "$TMPDIR/pylibraft" "$STUBS_DIR"

echo "Done. Generated $GENERATED stub files."

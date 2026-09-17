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

# Runtime workarounds for ROCm packaging quirks, applied by the hipRAFT CI test
# scripts. Meant to be sourced, not executed directly.
#
# Everything in here exists to paper over a packaging bug elsewhere, so each
# entry documents which layout it compensates for and stays a no-op on the
# layout it does not. When the upstream packaging is fixed, the corresponding
# function should be deleted outright rather than kept around.
#
# Provides:
#   setup_hipblaslt_tensile_libpath() -- points HIPBLASLT_TENSILE_LIBPATH at
#                                        TheRock's per-arch Tensile subdir

set -euo pipefail

# Returns 0 if a hipBLASLt lazy-load index exists directly under the directory
# given as $1 (which must end in "/"). Matches both the standard ROCm *.dat and
# TheRock's compressed *.dat.zlib variant.
_hipblaslt_has_lazy_index() {
    compgen -G "${1}TensileLibrary_lazy_*.dat" > /dev/null ||
    compgen -G "${1}TensileLibrary_lazy_*.dat.zlib" > /dev/null
}


# Works around TheRock-based ROCm packaging hipBLASLt's Tensile kernel data
# under a per-architecture subdirectory (.../hipblaslt/library/<gfx_arch>/)
# instead of directly under .../hipblaslt/library/, where the hipBLASLt runtime
# expects the lazy-load index (TensileLibrary_lazy_<arch>.dat) and its kernels.
# Without this, any hipBLASLt matmul (e.g. ivf_pq's rotate_padded_centers)
# fails to load its kernels and aborts the process.
#
# When the per-arch layout is detected, point HIPBLASLT_TENSILE_LIBPATH at the
# matching subdir. Architecture-agnostic: globs for the lazy index rather than
# hardcoding a gfx target.
#
# No-op when:
#   - HIPBLASLT_TENSILE_LIBPATH is already set (respect an explicit override)
#   - the lazy index is already at the top level (standard ROCm layout)
#   - no per-arch subdir with a lazy index is found
setup_hipblaslt_tensile_libpath() {
    if [ -n "${HIPBLASLT_TENSILE_LIBPATH:-}" ]; then
        return 0
    fi

    local lib_root="${ROCM_PATH:-/opt/rocm}/lib/hipblaslt/library"
    [ -d "${lib_root}" ] || return 0

    # Standard ROCm layout: the lazy index sits at the top level. Nothing to do.
    if _hipblaslt_has_lazy_index "${lib_root}/"; then
        return 0
    fi

    # TheRock layout: the lazy index lives in a per-arch subdir. Prefer the
    # subdir matching this machine's GPU arch, falling back to the first subdir
    # that carries a lazy index.
    local arch=""
    if command -v rocminfo > /dev/null 2>&1; then
        arch=$(rocminfo 2>/dev/null |
               awk 'match($0, /gfx[0-9a-f]+/) { print substr($0, RSTART, RLENGTH); exit }' ||
               true)
    fi
    if [ -z "${arch}" ]; then
        # AMDGPU_TARGETS may be a ;/,/space-separated list; take the first entry.
        arch=$(echo "${AMDGPU_TARGETS:-}" | tr ',;' '  ' | awk '{print $1}')
    fi

    if [ -n "${arch}" ] && _hipblaslt_has_lazy_index "${lib_root}/${arch}/"; then
        export HIPBLASLT_TENSILE_LIBPATH="${lib_root}/${arch}"
    else
        local dir
        for dir in "${lib_root}"/*/; do
            if _hipblaslt_has_lazy_index "${dir}"; then
                export HIPBLASLT_TENSILE_LIBPATH="${dir%/}"
                break
            fi
        done
    fi

    if [ -n "${HIPBLASLT_TENSILE_LIBPATH:-}" ]; then
        echo "Set HIPBLASLT_TENSILE_LIBPATH=${HIPBLASLT_TENSILE_LIBPATH}" \
             "(TheRock hipBLASLt layout WAR)"
    fi
}

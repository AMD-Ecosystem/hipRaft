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

# Build the hipRAFT wheel matrix inside a manylinux container.
#
# One build-wheels.sh pass per wheel and matrix entry, all of them writing into
# the same BUILD_ARTIFACTS_DIR, so the stage ends with a single wheel pool that
# covers the whole supported interpreter range:
#
#   amd_libraft    ... py3-none ... once, python/libraft sets wheel.py-api =
#                      "py3", so the wheel carries no interpreter tag
#   amd_pylibraft  ... one per entry, because the Cython extensions under
#   amd_raft_dask      pylibraft/ and raft_dask/ are compiled code. Both are
#                      built in the same pass: they share an interpreter and a
#                      tag, and raft-dask builds against pylibraft anyway.
#
# NOTE(HIP/AMD): amd_raft_dask is opt-in via HIPRAFT_ENABLE_RAFT_DASK ("true" to
# build, default off). It is disabled by default because raft-dask compiles
# hipUCXX from source, whose configure currently fails on a rocprim/hipCCL cmake
# export-set collision. The central toggle lives in the builder-tester env file
# (_envs/rocmds/<branch>) and is threaded here through the image ENV; test-wheels.sh
# gates the matching test the same way. When off, the pass below and the
# verification loops treat amd_raft_dask as if it were not part of the matrix.
#
#     3.11, no SABI    -> cp311-cp311
#     3.12, SABI 3.12  -> cp312-abi3, which installs on 3.12 and on every later
#                         CPython, so the tail of the range needs no build of
#                         its own
#
# No 3.9 or 3.10 entry: all three packages declare requires-python >= 3.11, so
# such a wheel would be rejected by pip on the interpreter it was built for.
#
# Manylinux-specific by construction: the interpreters come from
# /opt/python/cp<xy>-cp<xy>, which is a manylinux layout. Another distro wants
# a sibling driver rather than a fallback hidden in here.
#
# Run this after build-dev.sh, never before: build-wheels.sh sources
# _build-preamble.sh, which recreates ${INSTALL_DIR}/venv/hipraft_dev with
# --clear, and that venv is what build-dev.sh packs into the tests tarball.
#
# Required environment variables:
#   PROJECT_ID, SRC_DIR, BUILD_DIR, INSTALL_DIR, BUILD_ARTIFACTS_DIR
#   Everything else build-wheels.sh reads (AMDGPU_TARGETS, ROCM_PATH,
#   CMAKE_VERSION, CMAKE_INSTALL_PREFIX, ...) is passed through untouched.
#   BUILD_DIR, USE_SABI, HIPRAFT_BUILD_TYPE and the three HIPRAFT_BUILD_*
#   switches are the exceptions: this script sets them per pass.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${PROJECT_ID:?PROJECT_ID must be set}"
: "${SRC_DIR:?SRC_DIR must be set}"
: "${BUILD_DIR:?BUILD_DIR must be set}"
: "${INSTALL_DIR:?INSTALL_DIR must be set}"
: "${BUILD_ARTIFACTS_DIR:?BUILD_ARTIFACTS_DIR must be set}"

# build-wheels.sh reads these from the environment, and a caller that assigned
# them without exporting would otherwise hand it nothing.
export PROJECT_ID SRC_DIR INSTALL_DIR BUILD_ARTIFACTS_DIR

mkdir -p "${BUILD_ARTIFACTS_DIR}"

### the matrix, and the interpreters it needs
#
# The floor "no" clears the wheel.py-api pin the packages carry, for a tag
# specific to the building interpreter. 3.12 carries the abi3 floor, so 3.13
# and later install its wheel and need no pass of their own.
#
# A version this image does not carry should fail in seconds rather than after
# the first pass has spent an hour compiling.

# shellcheck source=ci/internal/_coverage.sh
source "${BASH_SOURCE[0]%/*}/_coverage.sh"
if coverage_enabled; then
  python_versions=(3.12)
  sabi_floors=(3.12)
  expected_tags=(cp312-abi3)
  python_bins=(/opt/python/cp312-cp312/bin)
else
  python_versions=(3.11 3.12)
  sabi_floors=(no 3.12)
  expected_tags=(cp311-cp311 cp312-abi3)
  python_bins=(/opt/python/cp311-cp311/bin /opt/python/cp312-cp312/bin)
fi

for python_bin in "${python_bins[@]}"; do
  if [ ! -x "${python_bin}/python" ]; then
    echo "ERROR: ${python_bin}/python is missing." >&2
    exit 1
  fi
done

### build
#
# Its own BUILD_DIR per pass: build-wheels.sh copies the checkout there and
# removes it again only when it succeeds, so a tree left behind by a failed
# pass would be copied over, cmake cache and all, by the next one.

base_path=${PATH}

# The wheel build types are the ones _install-build-deps.sh installs the pooled
# dependency wheels for, and pylibraft needs them: its .pyx files cimport
# rmm.librmm.cuda_stream_pool and cuda.bindings.cyruntime. Set per pass rather
# than taken from the caller, which may well have asked build-dev.sh for a
# C++-only build in the same run.
HIPRAFT_BUILD_TYPE=wheels

# amd_raft_dask is opt-in (see the note at the top). Translate the central
# HIPRAFT_ENABLE_RAFT_DASK toggle into the per-pass switch build-wheels.sh reads:
# "1" builds raft-dask, "" skips it.
if [ "${HIPRAFT_ENABLE_RAFT_DASK:-false}" = "true" ]; then
  raft_dask_switch=1
else
  raft_dask_switch=""
fi

echo "=============================================================="
echo "amd_libraft, built once with CPython ${python_versions[0]}"
echo "=============================================================="

# Any interpreter produces the same py3-none wheel; the matrix decides which
# one, so the pass does not depend on what the image happens to put on PATH.
PATH="${python_bins[0]}:${base_path}" \
BUILD_DIR="${BUILD_DIR}/libraft" \
HIPRAFT_BUILD_TYPE="${HIPRAFT_BUILD_TYPE}" \
HIPRAFT_BUILD_PYLIBRAFT="" \
HIPRAFT_BUILD_RAFT_DASK="" \
  "${SCRIPT_DIR}/build-wheels.sh"

for i in "${!python_versions[@]}"; do
  python_version=${python_versions[${i}]}
  sabi=${sabi_floors[${i}]}
  python_bin=${python_bins[${i}]}

  echo "=============================================================="
  echo "amd_pylibraft${raft_dask_switch:+ and amd_raft_dask} for CPython ${python_version} (USE_SABI=${sabi})"
  echo "=============================================================="

  PATH="${python_bin}:${base_path}" \
  BUILD_DIR="${BUILD_DIR}/cp${python_version//./}" \
  HIPRAFT_BUILD_TYPE="${HIPRAFT_BUILD_TYPE}" \
  HIPRAFT_BUILD_LIBRAFT="" \
  HIPRAFT_BUILD_RAFT_DASK="${raft_dask_switch}" \
  USE_SABI="${sabi}" \
    "${SCRIPT_DIR}/build-wheels.sh"
done

### verify the matrix produced the tags it promised
#
# The build is long and its failure modes are quiet: a missing tag only
# surfaces as an unsatisfiable install in the test stage, a stage and a
# container later. Check here, where the build log is still at hand.

shopt -s nullglob

missing=()

echo "=============================================================="
echo "Wheels in ${BUILD_ARTIFACTS_DIR}"
echo "=============================================================="

found=("${BUILD_ARTIFACTS_DIR}"/amd_libraft-*-py3-none-*.whl)
printf '  %-16s %-14s %d wheel(s)\n' "amd_libraft" "py3-none" "${#found[@]}"
if [ ${#found[@]} -eq 0 ]; then
  missing+=("amd_libraft (py3-none)")
fi

# A floor above the building interpreter is not an error to scikit-build-core,
# it silently drops back to a version-specific tag, and this is where such an
# entry would surface.
#
# Cython wheels to verify: amd_raft_dask only when the toggle built it.
verify_dists=(amd_pylibraft)
[ -n "${raft_dask_switch}" ] && verify_dists+=(amd_raft_dask)
for dist in "${verify_dists[@]}"; do
  for i in "${!expected_tags[@]}"; do
    expected_tag=${expected_tags[${i}]}

    found=("${BUILD_ARTIFACTS_DIR}"/"${dist}"-*-"${expected_tag}"-*.whl)
    printf '  %-16s %-14s %d wheel(s)\n' "${dist}" "${expected_tag}" "${#found[@]}"
    if [ ${#found[@]} -eq 0 ]; then
      missing+=("${dist} from CPython ${python_versions[${i}]} (${expected_tag})")
    fi
  done
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "ERROR: the wheel matrix is incomplete. Nothing produced:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  echo "Wheels that are present:" >&2
  ls -1 "${BUILD_ARTIFACTS_DIR}" >&2 || true
  exit 1
fi

unexpected=()
for dist in "${verify_dists[@]}"; do
  for bad_tag in cp312-cp312 cp313-cp313; do
    found=("${BUILD_ARTIFACTS_DIR}"/"${dist}"-*-"${bad_tag}"-*.whl)
    if [ ${#found[@]} -gt 0 ]; then
      unexpected+=("${dist} ${bad_tag} (${#found[@]} wheel(s))")
    fi
  done
done
if [ ${#unexpected[@]} -gt 0 ]; then
  echo "ERROR: version-specific wheels outside the matrix:" >&2
  printf '  - %s\n' "${unexpected[@]}" >&2
  ls -1 "${BUILD_ARTIFACTS_DIR}"/amd_pylibraft*.whl "${BUILD_ARTIFACTS_DIR}"/amd_raft_dask*.whl >&2 || true
  exit 1
fi

echo "Wheel matrix complete."

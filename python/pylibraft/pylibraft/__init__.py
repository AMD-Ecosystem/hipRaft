# SPDX-FileCopyrightText: Copyright (c) 2022-2024, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
#

# MIT License
#
# Modifications Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.
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

# If libraft was installed as a wheel, we must request it to load the library
# symbols. Otherwise, we assume that the library was installed in a system path that ld
# can find.
import glob
import os

# NOTE:
# Both hipBLASLt and rocBLAS attempt to load Tensile artifacts
# *relative to the .so path* by default. This behavior is fine on
# system installs, but becomes problematic for manylinux wheels
# since the shared libraries are relocated into the wheel’s
# internal layout (not the standard ROCm directory structure).
# To avoid runtime load failures, we set the following environment
# variables to point explicitly to the correct artifact directories.
# These are only set if not already defined by the user.


def _tensile_libpath(root):
    """Resolve the Tensile artifact directory for ``root``.

    (HIP/AMD) Stock ROCm keeps the Tensile index directly under ``root``,
    but TheRock-based packaging puts it in a per-arch subdirectory
    (``root/<gfx_arch>/``). Pointing the runtime at ``root`` in that layout
    makes it load no kernels at all: every matmul then fails with
    ``*_STATUS_INVALID_VALUE`` and ``returnedAlgoCount=0``. Return the
    subdirectory in that case, and ``root`` otherwise so system installs and
    relocated wheels keep their existing behaviour.
    """
    index = "TensileLibrary*.dat*"
    try:
        if glob.glob(os.path.join(root, index)):
            return root
        arch_dirs = [
            d.rstrip(os.sep)
            for d in sorted(glob.glob(os.path.join(root, "*", "")))
            if glob.glob(os.path.join(d, index))
        ]
        if len(arch_dirs) == 1:
            return arch_dirs[0]
        # Several archs shipped: pick the one the build targets, if known.
        target = (
            os.environ.get("AMDGPU_TARGETS", "")
            .replace(";", ",")
            .split(",")[0]
            .strip()
        )
        for d in arch_dirs:
            if target and os.path.basename(d) == target:
                return d
    except OSError:
        pass
    return root


for _var, _root in (
    ("HIPBLASLT_TENSILE_LIBPATH", "/opt/rocm/lib/hipblaslt/library"),
    ("ROCBLAS_TENSILE_LIBPATH", "/opt/rocm/lib/rocblas/library"),
):
    if _var not in os.environ:
        os.environ[_var] = _tensile_libpath(_root)

try:
    import libraft
except ModuleNotFoundError:
    pass
else:
    libraft.load_library()
    del libraft

from pylibraft._version import __git_commit__, __version__

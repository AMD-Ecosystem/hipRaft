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

from __future__ import annotations
import glob as glob
import os as os
from . import _version
__all__: list[str] = ['glob', 'os']
def _tensile_libpath(root):
    """
    Resolve the Tensile artifact directory for ``root``.
    
    (HIP/AMD) Stock ROCm keeps the Tensile index directly under ``root``,
    but TheRock-based packaging puts it in a per-arch subdirectory
    (``root/<gfx_arch>/``). Pointing the runtime at ``root`` in that layout
    makes it load no kernels at all: every matmul then fails with
    ``*_STATUS_INVALID_VALUE`` and ``returnedAlgoCount=0``. Return the
    subdirectory in that case, and ``root`` otherwise so system installs and
    relocated wheels keep their existing behaviour.
    """
__git_commit__: str = ''
__version__: str = '02.00.00'
_root: str = '/opt/rocm/lib/rocblas/library'
_var: str = 'ROCBLAS_TENSILE_LIBPATH'

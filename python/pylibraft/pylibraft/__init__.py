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

os.environ.setdefault(
    "HIPBLASLT_TENSILE_LIBPATH", "/opt/rocm/lib/hipblaslt/library"
)

os.environ.setdefault(
    "ROCBLAS_TENSILE_LIBPATH", "/opt/rocm/lib/rocblas/library"
)

try:
    import libraft
except ModuleNotFoundError:
    pass
else:
    libraft.load_library()
    del libraft

from pylibraft._version import __git_commit__, __version__

# SPDX-FileCopyrightText: Copyright (c) 2022-2024, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
#

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

# Copyright (c) 2022-2024, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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

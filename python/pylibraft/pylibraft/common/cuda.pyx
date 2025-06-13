#
# Copyright (c) 2022-2023, NVIDIA CORPORATION.
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
# MIT License
#
# Modifications Copyright (c) 2025 Advanced Micro Devices, Inc.
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

# cython: profile=False
# distutils: language = c++
# cython: embedsignature = True
# cython: language_level = 3

# TODO(HIP-PYTHON) Once https://github.com/AMD-AI/hip-python/pull/3 has merged
# and made public, uncomment the line below and remove the line underneath

# from cuda.bindings.cyruntime cimport (

from cuda.ccuda cimport (
    cudaError_t,
    cudaGetErrorName,
    cudaGetErrorString,
    cudaGetLastError,
    cudaStream_t,
    cudaStreamCreate,
    cudaStreamDestroy,
    cudaStreamSynchronize,
    cudaSuccess,
)
from libc.stdint cimport uintptr_t


class CudaRuntimeError(RuntimeError):
    def __init__(self, extraMsg=None):
        cdef cudaError_t e = cudaGetLastError()
        cdef bytes errMsg = cudaGetErrorString(e)
        cdef bytes errName = cudaGetErrorName(e)
        msg = "Error! %s reason='%s'" % (errName.decode(), errMsg.decode())
        if extraMsg is not None:
            msg += " extraMsg='%s'" % extraMsg
        super(CudaRuntimeError, self).__init__(msg)


cdef class Stream:
    """
    Stream represents a thin-wrapper around cudaStream_t and its operations.

    Examples
    --------

    >>> from pylibraft.common.cuda import Stream
    >>> stream = Stream()
    >>> stream.sync()
    >>> del stream  # optional!
    """
    def __cinit__(self):
        cdef cudaStream_t stream
        cdef cudaError_t e = cudaStreamCreate(&stream)
        if e != cudaSuccess:
            raise CudaRuntimeError("Stream create")
        self.s = stream

    def __dealloc__(self):
        self.sync()
        cdef cudaError_t e = cudaStreamDestroy(self.s)
        if e != cudaSuccess:
            raise CudaRuntimeError("Stream destroy")

    def sync(self):
        """
        Synchronize on the cudastream owned by this object. Note that this
        could raise exception due to issues with previous asynchronous
        launches
        """
        cdef cudaError_t e = cudaStreamSynchronize(self.s)
        if e != cudaSuccess:
            raise CudaRuntimeError("Stream sync")

    cdef cudaStream_t getStream(self):
        return self.s

    def get_ptr(self):
        """
        Return the uintptr_t pointer of the underlying cudaStream_t handle
        """
        return <uintptr_t>self.s

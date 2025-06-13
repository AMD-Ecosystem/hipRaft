#
# Copyright (c) 2021-2024, NVIDIA CORPORATION.
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

# Modifications Copyright (c) 2025 Advanced Micro Devices, Inc.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# cython: profile=False
# distutils: language = c++
# cython: embedsignature = True
# cython: language_level = 3

import contextlib
import signal

# TODO(HIP-PYTHON) Once https://github.com/AMD-AI/hip-python/pull/3 has merged
# and made public, remove the line below

from cuda.ccuda cimport cudaStream_t
# from cuda.bindings.cyruntime cimport cudaStream_t
from cython.operator cimport dereference

# Once hipMM has been updated to version 25.02, remove the line below
# and uncomment the line under it
from rmm._lib.cuda_stream_view cimport cuda_stream_view

from .cuda cimport Stream

# from rmm.librmm.cuda_stream_view cimport cuda_stream_view


@contextlib.contextmanager
def cuda_interruptible():
    '''
    Temporarily install a keyboard interrupt handler (Ctrl+C)
    that cancels the enclosed interruptible C++ thread.

    Use this on a long-running C++ function imported via cython:

    >>> with cuda_interruptible():
    >>>     my_long_running_function(...)

    It's also recommended to release the GIL during the call, to
    make sure the handler has a chance to run:

    >>> with cuda_interruptible():
    >>>     with nogil:
    >>>         my_long_running_function(...)
    '''
    cdef shared_ptr[interruptible] token = get_token()

    def newhr(*args, **kwargs):
        with nogil:
            dereference(token).cancel()

    try:
        oldhr = signal.signal(signal.SIGINT, newhr)
    except ValueError:
        # the signal creation would fail if this is not the main thread
        # That's fine! The feature is disabled.
        oldhr = None
    try:
        yield
    finally:
        if oldhr is not None:
            signal.signal(signal.SIGINT, oldhr)


def synchronize(stream: Stream):
    '''
    Same as cudaStreamSynchronize, but can be interrupted
    if called within a `with cuda_interruptible()` block.
    '''
    cdef cuda_stream_view c_stream = cuda_stream_view(stream.getStream())
    with nogil:
        inter_synchronize(c_stream)


def cuda_yield():
    '''
    Check for an asynchronously received interrupted_exception.
    Raises the exception if a user pressed Ctrl+C within a
    `with cuda_interruptible()` block before.
    '''
    with nogil:
        inter_yield()

#
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


from libcpp.memory cimport shared_ptr, unique_ptr

# Once hipmm has been updated to version 25.02, remove the two lines below and
# uncomment the two lines below
from rmm._lib.cuda_stream_pool cimport cuda_stream_pool
from rmm._lib.cuda_stream_view cimport cuda_stream_view

# from rmm.librmm.cuda_stream_pool cimport cuda_stream_pool
# from rmm.librmm.cuda_stream_view cimport cuda_stream_view

# Keeping `handle_t` around for backwards compatibility at the
# cython layer but users are encourage to switch to device_resources
cdef extern from "raft/core/handle.hpp" namespace "raft" nogil:
    cdef cppclass handle_t:
        handle_t() except +
        handle_t(cuda_stream_view stream_view) except +
        handle_t(cuda_stream_view stream_view,
                 shared_ptr[cuda_stream_pool] stream_pool) except +
        cuda_stream_view get_stream() except +
        void sync_stream() except +


cdef extern from "raft/core/device_resources.hpp" namespace "raft" nogil:
    cdef cppclass device_resources:
        device_resources() except +
        device_resources(cuda_stream_view stream_view) except +
        device_resources(cuda_stream_view stream_view,
                         shared_ptr[cuda_stream_pool] stream_pool) except +
        cuda_stream_view get_stream() except +
        void sync_stream() except +

cdef class DeviceResources:
    cdef unique_ptr[device_resources] c_obj
    cdef shared_ptr[cuda_stream_pool] stream_pool
    cdef int n_streams

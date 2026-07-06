# MIT License
#
# Modifications Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.
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
import builtins as __builtins__
import typing
__all__: list[str] = ['CudaRuntimeError', 'Stream']
class CudaRuntimeError(RuntimeError):
    def __init__(self, extraMsg = None):
        """
        CudaRuntimeError.__init__(self, extraMsg=None)
        """
class Stream:
    """
    
        Stream represents a thin-wrapper around cudaStream_t and its operations.
    
        Examples
        --------
    
        >>> from pylibraft.common.cuda import Stream
        >>> stream = Stream()
        >>> stream.sync()
        >>> del stream  # optional!
        
    """
    __pyx_vtable__: typing.ClassVar[typing.Any]  # value = <capsule object>
    @staticmethod
    def __new__(type, *args, **kwargs):
        """
        Create and return a new object.  See help(type) for accurate signature.
        """
    @staticmethod
    def __reduce__(*args, **kwargs):
        """
        Stream.__reduce_cython__(self)
        """
    @staticmethod
    def __setstate__(*args, **kwargs):
        """
        Stream.__setstate_cython__(self, __pyx_state)
        """
    def get_ptr(self):
        """
        Stream.get_ptr(self)
        
        Return the uintptr_t pointer of the underlying cudaStream_t handle
        """
    def sync(self):
        """
        Stream.sync(self)
        
        Synchronize on the cudastream owned by this object. Note that this
        could raise exception due to issues with previous asynchronous
        launches
        """
def __reduce_cython__(self):
    """
    Stream.__reduce_cython__(self)
    """
def __setstate_cython__(self, __pyx_state):
    """
    Stream.__setstate_cython__(self, __pyx_state)
    """
__test__: dict = {}

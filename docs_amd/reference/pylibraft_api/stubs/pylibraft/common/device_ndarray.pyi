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
import numpy
import numpy as np
import rmm as rmm
__all__: list[str] = ['device_ndarray', 'np', 'rmm']
class device_ndarray:
    """
    
        pylibraft.common.device_ndarray is meant to be a very lightweight
        __cuda_array_interface__ wrapper around a numpy.ndarray.
        
    """
    @classmethod
    def empty(cls, shape, dtype = numpy.float32, order = 'C'):
        """
        
                Return a new device_ndarray of given shape and type, without
                initializing entries.
        
                Parameters
                ----------
                shape : int or tuple of int
                        Shape of the empty array, e.g., (2, 3) or 2.
                dtype : data-type, optional
                        Desired output data-type for the array, e.g, numpy.int8.
                        Default is numpy.float32.
                order : {'C', 'F'}, optional (default: 'C')
                        Whether to store multi-dimensional dat ain row-major (C-style)
                        or column-major (Fortran-style) order in memory
                
        """
    def __init__(self, np_ndarray):
        """
        
                Construct a pylibraft.common.device_ndarray wrapper around a
                numpy.ndarray
        
                Parameters
                ----------
                ndarray : Can be numpy.ndarray, array like or even directly
                    an __array_interface__. Only case it is a numpy.ndarray its
                    contents will be copied to the device.
        
                Examples
                --------
                The device_ndarray is __cuda_array_interface__ compliant so it is
                interoperable with other libraries that also support it, such as
                CuPy and PyTorch.
        
                The following usage example demonstrates
                converting a pylibraft.common.device_ndarray to a cupy.ndarray:
                .. code-block:: python
        
                    import cupy as cp
                    from pylibraft.common import device_ndarray
        
                    raft_array = device_ndarray.empty((100, 50))
                    cupy_array = cp.asarray(raft_array)
        
                And the converting pylibraft.common.device_ndarray to a PyTorch tensor:
                .. code-block:: python
        
                    import torch
                    from pylibraft.common import device_ndarray
        
                    raft_array = device_ndarray.empty((100, 50))
                    torch_tensor = torch.as_tensor(raft_array, device='cuda')
                
        """
    def copy_to_host(self):
        """
        
                Returns a new numpy.ndarray object on host with the current contents of
                this device_ndarray
                
        """
    @property
    def __cuda_array_interface__(self):
        """
        
                Returns the __cuda_array_interface__ compliant dict for
                integrating with other device-enabled libraries using
                zero-copy semantics.
                
        """
    @property
    def c_contiguous(self):
        """
        
                Is the current device_ndarray laid out in row-major format?
                
        """
    @property
    def dtype(self):
        """
        
                Datatype of the current device_ndarray instance
                
        """
    @property
    def f_contiguous(self):
        """
        
                Is the current device_ndarray laid out in column-major format?
                
        """
    @property
    def shape(self):
        """
        
                Shape of the current device_ndarray instance
                
        """
    @property
    def strides(self):
        """
        
                Strides of the current device_ndarray instance
                
        """

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
import functools as functools
import pylibraft as pylibraft
import warnings as warnings
__all__: list[str] = ['auto_convert_output', 'conv', 'convert_to_cai_type', 'convert_to_cupy', 'convert_to_torch', 'functools', 'import_warn_', 'no_conversion', 'pylibraft', 'warnings']
def auto_convert_output(f):
    """
    Decorator to automatically convert an output device_ndarray
        (or list or tuple of device_ndarray) into the configured
        `__cuda_array_interface__` compliant type.
        
    """
def conv(ret):
    ...
def convert_to_cai_type(device_ndarray):
    ...
def convert_to_cupy(device_ndarray):
    ...
def convert_to_torch(device_ndarray):
    ...
def import_warn_(lib):
    ...
def no_conversion(device_ndarray):
    ...

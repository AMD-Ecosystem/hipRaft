# SPDX-FileCopyrightText: Copyright (c) 2022-2023, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
#

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
import pylibraft.common.ai_wrapper
from pylibraft.common.ai_wrapper import ai_wrapper
from types import SimpleNamespace
__all__: list[str] = ['SimpleNamespace', 'ai_wrapper', 'cai_wrapper', 'wrap_array']
class cai_wrapper(pylibraft.common.ai_wrapper.ai_wrapper):
    """
    
    Simple wrapper around a CUDA array interface object to reduce
    boilerplate for extracting common information from the underlying
    dictionary.
    """
    def __init__(self, cai_arr):
        """
        
        Constructor accepts a CUDA array interface compliant array
        
        Parameters
        ----------
        cai_arr : CUDA array interface array
        """
def wrap_array(array):
    ...

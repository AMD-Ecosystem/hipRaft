..
   MIT License

   Modifications Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

.. _pylibraft-python:

pylibraft
=========

``pylibraft`` is the Python interface to hipRAFT's core algorithms and data
structures. It provides high-performance, GPU-accelerated primitives for common machine
learning and data analytics operations, including device resource management, distance
computations, random matrix generation, and sparse matrix utilities. ``pylibraft`` is
designed to integrate with the CUDA Array Interface(which has been extended to support
cupy and numba-hip) for interoperability with other GPU-based Python libraries.

* :doc:`common```
* :doc:`random`
* :doc:`sparse`

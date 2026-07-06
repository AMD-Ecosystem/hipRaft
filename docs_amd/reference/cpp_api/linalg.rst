..
    MIT License

    Modifications Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.

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

Linear Algebra
==============

This page provides C++ class references for the publicly-exposed elements of the `raft/linalg` (dense) linear algebra headers.
In addition to providing highly optimized arithmetic and matrix/vector operations, hipRAFT provides a consistent user experience
by providing common BLAS routines, standard linear system solvers, factorization and eigenvalue solvers. Some of these routines
hide the complexities of lower-level C-based libraries provided in the ROCm toolkit (hipBLAS, hipBLASLt, hipSOLVER)

.. role:: py(code)
   :language: c++
   :class: highlight

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   linalg_arithmetic.rst
   linalg_blas.rst
   linalg_map_reduce.rst
   linalg_matrix.rst
   linalg_matrix_vector.rst
   linalg_solver.rst

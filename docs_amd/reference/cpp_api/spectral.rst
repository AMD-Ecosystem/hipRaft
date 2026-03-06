..
    MIT License

    Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.

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

Spectral
========

.. role:: py(code)
   :language: c++
   :class: highlight

This page provides C++ class references for the publicly-exposed elements of the `raft/spectral` package.
The spectral methods in RAFT provide graph-based clustering and partitioning algorithms that operate on
sparse matrix representations.

Graph Partitioning
------------------

``#include <raft/spectral/partition.cuh>``

namespace *raft::spectral*

.. doxygengroup:: spectral_partition
    :project: RAFT
    :members:
    :content-only:

Modularity Maximization
-----------------------

``#include <raft/spectral/modularity_maximization.cuh>``

namespace *raft::spectral*

.. doxygengroup:: spectral_modularity
    :project: RAFT
    :members:
    :content-only:

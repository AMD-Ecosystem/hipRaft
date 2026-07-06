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

Multi-dimensional Representation
================================

.. role:: py(code)
   :language: c++
   :class: highlight

Data Layouts
-------------

``#include <raft/core/mdspan_types.hpp>``

.. doxygengroup:: mdspan_layout
    :project: RAFT
    :members:
    :content-only:

Shapes
------

``#include <raft/core/mdspan.hpp>``

.. doxygentypedef:: raft::matrix_extent
    :project: RAFT

.. doxygentypedef:: raft::vector_extent
    :project: RAFT

.. doxygentypedef:: raft::scalar_extent
    :project: RAFT

.. doxygentypedef:: raft::extent_3d
    :project: RAFT

.. doxygentypedef:: raft::extent_4d
    :project: RAFT

.. doxygentypedef:: raft::extent_5d
    :project: RAFT

.. doxygengroup:: mdspan_reshape
    :project: RAFT
    :members:
    :content-only:

.. doxygengroup:: mdarray_reshape
    :project: RAFT
    :members:
    :content-only:


Accessors
---------

``#include <raft/core/host_device_accessor.hpp>``

.. doxygenstruct:: raft::host_device_accessor
    :project: RAFT
    :members:

.. doxygentypedef:: raft::host_accessor
    :project: RAFT

.. doxygentypedef:: raft::device_accessor
    :project: RAFT

.. doxygentypedef:: raft::managed_accessor
    :project: RAFT

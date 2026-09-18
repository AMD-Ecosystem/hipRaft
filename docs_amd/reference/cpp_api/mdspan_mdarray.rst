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

mdarray: Multi-dimensional Owning Container
===========================================

.. role:: py(code)
   :language: c++
   :class: highlight

``#include <raft/core/mdarray.hpp>``

.. doxygengroup:: mdarray_apis
    :project: RAFT
    :members:
    :content-only:

Device Vocabulary
-----------------

``#include <raft/core/device_mdarray.hpp>``

.. doxygentypedef:: raft::device_mdarray
    :project: RAFT

.. doxygentypedef:: raft::device_matrix
    :project: RAFT

.. doxygentypedef:: raft::device_vector
    :project: RAFT

.. doxygentypedef:: raft::device_scalar
    :project: RAFT


Device Factories
----------------

``#include <raft/core/device_mdarray.hpp>``

.. doxygenfunction:: raft::make_device_matrix
    :project: RAFT

.. doxygenfunction:: raft::make_device_vector
    :project: RAFT

.. doxygenfunction:: raft::make_device_scalar(raft::resources const &handle)
    :project: RAFT

.. doxygenfunction:: raft::make_device_scalar(raft::resources const &handle, ElementType const &v)
    :project: RAFT


Host Vocabulary
---------------

``#include <raft/core/host_mdarray.hpp>``

.. doxygentypedef:: raft::host_matrix
    :project: RAFT

.. doxygentypedef:: raft::host_vector
    :project: RAFT

.. doxygentypedef:: raft::host_scalar
    :project: RAFT


Host Factories
--------------

``#include <raft/core/host_mdarray.hpp>``

.. doxygengroup:: host_mdarray_factories
    :project: RAFT
    :members:
    :content-only:

Managed Vocabulary
------------------

``#include <raft/core/managed_mdarray.hpp>``

.. doxygentypedef:: raft::managed_mdarray
    :project: RAFT

.. doxygentypedef:: raft::managed_matrix
    :project: RAFT

.. doxygentypedef:: raft::managed_vector
    :project: RAFT

.. doxygentypedef:: raft::managed_scalar
    :project: RAFT


Managed Factories
-----------------

``#include <raft/core/managed_mdarray.hpp>``

.. doxygenfunction:: raft::make_managed_matrix
    :project: RAFT

.. doxygenfunction:: raft::make_managed_vector
    :project: RAFT

.. doxygenfunction:: raft::make_managed_scalar
    :project: RAFT

Pinned Vocabulary
-----------------

``#include <raft/core/pinned_mdarray.hpp>``

.. doxygentypedef:: raft::pinned_mdarray
    :project: RAFT

.. doxygentypedef:: raft::pinned_matrix
    :project: RAFT

.. doxygentypedef:: raft::pinned_vector
    :project: RAFT

.. doxygentypedef:: raft::pinned_scalar
    :project: RAFT


Pinned Factories
----------------

``#include <raft/core/pinned_mdarray.hpp>``

.. doxygenfunction:: raft::make_pinned_matrix
    :project: RAFT

.. doxygenfunction:: raft::make_pinned_vector
    :project: RAFT

.. doxygenfunction:: raft::make_pinned_scalar
    :project: RAFT

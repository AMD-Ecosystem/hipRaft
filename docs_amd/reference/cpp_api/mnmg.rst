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

Multi-node Multi-GPU
====================

.. note::
    These APIs are experimental, may change in future releases, and are not officially supported by hipRAFT on the AMD platform.

hipRAFT contains C++ infrastructure for abstracting the communications layer when writing applications that scale on multiple nodes and across multiple GPUs. This infrastructure assumes OPG (one-process per GPU) architectures where multiple physical parallel units (processes, ranks, or workers) might be executing code concurrently but where each parallel unit is communicating with only a single GPU and is the only process communicating with each GPU.

The comms layer in RAFT is intended to provide a facade API for barrier synchronous collective communications, allowing users to write algorithms using a single abstraction layer and deploy in many different types of systems. Currently, RAFT communications code has been deployed in MPI, Dask, and Spark clusters.

.. role:: py(code)
   :language: c++
   :class: highlight

Common Types
------------

``#include <raft/core/comms.hpp>``

namespace *raft::comms*

.. doxygengroup:: comms_types
    :project: RAFT
    :members:
    :content-only:


Comms Interface
---------------

.. doxygengroup:: comms_t
    :project: RAFT
    :members:
    :content-only:


MPI Comms
---------

.. doxygengroup:: mpi_comms_factory
    :project: RAFT
    :members:
    :content-only:


RCCL+UCX Comms
--------------

.. doxygengroup:: std_comms_factory
    :project: RAFT
    :members:
    :content-only:

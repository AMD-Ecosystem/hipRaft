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

.. meta::
  :description: hipGRAPH documentation and API reference library
  :keywords: Graph, Graph-algorithms, Graph-analysis, Graph-processing, Complex-networks, rocGraph, hipGraph, cuGraph, NetworkX, GPU, RAPIDS, ROCm-DS

.. _hipraft-python:

*********************************
hipRAFT Python API documentation
*********************************

hipRAFT ships two Python packages serving distinct roles:

* :doc:`pylibraft_api/index` is the core Python library, providing single-GPU,
  high-performance primitives that map directly onto the underlying C++ API. It is the
  primary entry point for most users and covers device resource management, random matrix
  generation, sparse operations, and more.

* :doc:`hipraft_dask_api/index` is a complementary package for multi-node, multi-GPU
  workloads. It builds on top of ``pylibraft`` and Dask to provide distributed
  communicator abstractions (NCCL, UCX/UCXX), enabling collective operations across GPU
  clusters. Use ``raft_dask`` when your workflow spans more than one GPU or node.
  **Note:** ``raft_dask`` is experimental and has limited testing.

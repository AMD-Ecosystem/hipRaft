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

.. _hipraft-dask-python:

raft_dask
=========

.. warning::

   ``raft_dask`` is experimental. Testing is limited and it may not be fully validated.

``raft_dask`` extends hipRAFT to multi-node, multi-GPU (MNMG) environments using Dask
for distributed task scheduling. It provides communicator abstractions built on NCCL and
UCX/UCXX that enable scalable collective operations (all-reduce, broadcast, gather, etc.)
across GPU clusters. ``raft_dask`` is intended for distributed workflows where computation
must be coordinated across multiple GPUs on one or more nodes.

* :doc:`common`

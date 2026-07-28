..
    MIT License

    Copyright (C) 2025 Advanced Micro Devices, Inc. All rights reserved.

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
  :description: hipRAFT documentation and API reference library
  :keywords: Machine-Learning, Information-Retrieval, Primitives, Nearest-Neighbors, GPU, RAPIDS, AMD Data Science

.. _hipraft:

********************************************************************
hipRAFT documentation
********************************************************************

hipRAFT is a library of fundamental algorithms and primitives for machine-learning and data-mining workloads that can be run on AMD GPUs. It is part of the AMD Data Science toolkit, an open-source software collection for high-performance data science applications. Forked from the RAPIDS® RAFT project, hipRAFT brings the same rich functionality to the :doc:`HIP <hip:index>`/:doc:`ROCm <rocm:index>` stack while preserving the directory structure, file naming, and API naming, to minimize porting friction for developers using both projects. It offers both a modern C++ interface for systems developers and fully featured Python bindings for rapid prototyping and data-science workflows. For more information, see :doc:`What is hipRAFT? <what-is-hipRAFT>`

Key highlights in hipRAFT v1.0.0 include:

* Full integration with the AMD Data Science ecosystem – Serves as the computational foundation for hipGRAPH and hipVS, providing shared GPU-accelerated primitives across all components.
* Expanded C++ and Python support – Offers a modern C++ interface for system-level integration and Python bindings for rapid prototyping and data-science workflows.
* Rich module coverage – Delivers accelerated functionality across core domains, including:

  - Linear Algebra – GPU-optimized BLAS routines, solvers, and matrix factorizations.
  - Matrix Utilities – Advanced arithmetic, manipulation, and reduction operations.
  - Sparse Operations – Efficient computation and solvers for large-scale sparse data.
  - Label Processing – High-performance label extraction and remapping utilities for ML and graph algorithms.
  - Optimization Solvers – Support for linear assignment (Hungarian algorithm) and minimum spanning tree (MST) solvers.
  - Random Number Generation – GPU-based random utilities for ML training and simulation.

* Performance and resource management improvements – Enhanced GPU memory handling, logging, and profiling utilities for efficient large-scale computation.

The hipRAFT code is open and hosted at `https://github.com/AMD-Ecosystem/hipRaft <https://github.com/AMD-Ecosystem/hipRaft>`_.

.. grid:: 2
  :gutter: 3

  .. grid-item-card:: Installation

    * :doc:`System requirements <install/system-requirements>`
    * :doc:`Installing hipRAFT <install/install>`
    * :doc:`Building hipRAFT <install/build>`

  .. grid-item-card:: How to

    * :doc:`Use hipRAFT <how-to/using-hipRAFT>`

  .. grid-item-card:: API reference

    * :ref:`C++ API reference <hipraft-cpp>`
    * :ref:`Python API reference <hipraft-python>`


To contribute to the documentation refer to `Contributing to AMD Data Science  <https://rocm.docs.amd.com/projects/rocm-ds/en/latest/contribute/contributing.html>`_.

You can find licensing information on the `Licensing <https://rocm.docs.amd.com/projects/rocm-ds/en/latest/about/license.html>`_ page.

.. meta::
  :description: hipRAFT documentation and API reference library
  :keywords: Machine-Learning, Information-Retrieval, Primitives, Nearest-Neighbors, GPU, RAPIDS, ROCm-DS

.. _hipraft:

********************************************************************
hipRAFT documentation
********************************************************************

hipRAFT is a library of fundamental algorithms and primitives for machine-learning and data-mining workloads that can be run on AMD GPUs. It is part of the ROCm Data Science toolkit (or ROCm-DS), an open-source software collection for high-performance data science applications. Forked from the NVIDIA RAPIDS `https://github.com/rapidsai/raft <https://github.com/rapidsai/raft>`_ project, hipRAFT brings the same rich functionality to the :doc:`HIP <hip:index>`/:doc:`ROCm <rocm:index>` stack while preserving the directory structure, file naming, and API naming, to minimize porting friction for developers using both projects. It offers both a modern C++ interface for systems developers and fully featured Python bindings for rapid prototyping and data-science workflows. For more information, see :doc:`What is hipRAFT? <what-is-hipRAFT>`

Key highlights in hipRAFT v0.1.0 include:

* Full integration with the ROCm-DS ecosystem – Serves as the computational foundation for hipGRAPH and hipVS, providing shared GPU-accelerated primitives across all components.
* Expanded C++ and Python support – Offers a modern C++ interface for system-level integration and Python bindings for rapid prototyping and data-science workflows.
* Rich module coverage – Delivers accelerated functionality across core domains, including:

  - Linear Algebra – GPU-optimized BLAS routines, solvers, and matrix factorizations.
  - Matrix Utilities – Advanced arithmetic, manipulation, and reduction operations.
  - Sparse Operations – Efficient computation and solvers for large-scale sparse data.
  - Label Processing – High-performance label extraction and remapping utilities for ML and graph algorithms.
  - Optimization Solvers – Support for linear assignment (Hungarian algorithm) and minimum spanning tree (MST) solvers.
  - Random Number Generation – GPU-based random utilities for ML training and simulation.

* Performance and resource management improvements – Enhanced GPU memory handling, logging, and profiling utilities for efficient large-scale computation.

The hipRAFT code is open and hosted at `https://github.com/ROCm-DS/hipRaft <https://github.com/ROCm-DS/hipRaft>`_.

.. grid:: 2
  :gutter: 3

  .. grid-item-card:: Installation

    * :doc:`Installing hipRAFT <install/install>`
    * :doc:`Building hipRAFT <install/build>`

  .. grid-item-card:: How to

    * :doc:`Use hipRAFT <how-to/using-hipRAFT>`

  .. grid-item-card:: API reference

    * :ref:`C++ API reference <hipraft-cpp>`
    * :ref:`Python API reference <hipraft-python>`


To contribute to the documentation refer to `Contributing to ROCm-DS  <https://rocm.docs.amd.com/projects/rocm-ds/en/latest/contribute/contributing.html>`_.

You can find licensing information on the `Licensing <https://rocm.docs.amd.com/projects/rocm-ds/en/latest/about/license.html>`_ page.

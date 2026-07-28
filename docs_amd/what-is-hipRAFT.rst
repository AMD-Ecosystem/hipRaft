.. meta::
   :description: hipRAFT documentation and API reference
   :keywords: Machine-Learning, Information-Retrieval, Primitives, GPU, RAPIDS, AMD Data Science

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

******************
What is hipRAFT?
******************

hipRAFT is a library of functions for machine learning and data mining. It is AMD's ROCm-native
port of RAPIDS® RAFT: a collection of reusable, GPU-accelerated C++/Python primitives (distance, reductions,
neighbors, graph, sparse/dense linalg, etc.) built with HIP for AMD Instinct GPUs. It provides
RAFT-compatible APIs so data-science and ML libraries (e.g., vector search, clustering, graph analytics)
can run efficiently on ROCm without code rewrites. While not exhaustive, the following table summarizes
the accelerated functions in hipRAFT:

.. list-table::
   :header-rows: 1
   :widths: 15 25 60

   * - Module
     - Headers
     - Description

   * - `Core <./reference/cpp_api/core.html>`_
     - `cpp/include/raft/core/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/core>`_
     - * Spans, buffers, and memory allocation policies and containers.
       * GPU Resource Management – Streams, events, device properties.
       * Logging & Debugging – Logging macros, profiling utilities.
       * Sparse Dense Matrix Abstractions – COO and CSR matrix handling.
       * Known issues:

          * The API in ``raft/core/interruptible.hpp`` are not supported.

   * - **Label**
     - `cpp/include/raft/label/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/label>`_
     - These APIs provide functionalities for handling and processing class labels in machine learning and graph-based algorithms. They focus on extracting unique labels, mapping labels to a monotonically increasing order, and merging different label sets.

   * - `Linear Algebra <./reference/cpp_api/linalg.html>`_
     - `cpp/include/raft/linalg/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/linalg>`_
     - APIs that abstract common BLAS routines, standard linear system solvers, factorization and eigenvalue solvers.

       * Known issues:

          * ``raft::linalg::randomized_svd`` is not supported.

   * - `Matrix <./reference/cpp_api/matrix.html>`_
     - `cpp/include/raft/matrix/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/matrix>`_
     - The hipRAFT matrix API extends matrix operations beyond ``raft::linalg``, offering utilities for arithmetic (power, ratio, reciprocal, sign-flip, square root), manipulation (initialization, reversing, thresholding), ordering (argmax, argmin, select-K, sorting), and reductions (matrix norms).

   * - `Solver <./reference/cpp_api/solver.html>`_
     - `cpp/include/raft/solver/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/solver>`_
     - Solvers supported:

       * ``LinearAssignmentProblem`` solver(alternating tree Hungarian Algorithm) from ``cpp/include/raft/solver/linear_assignment.cuh``
       * ``Minimum spanning tree`` solver is supported from ``cpp/include/raft/sparse/mst/mst.hpp``

   * - `Sparse <./reference/cpp_api/sparse.html>`_
     - `cpp/include/raft/sparse/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/sparse>`_
     - Provides GPU-accelerated operations for sparse matrices, including arithmetic, normalization, multiplication, slicing, and solvers for eigenvalues and graph problems, optimizing large-scale computations.

       * Known issues:

          * ``raft::sparse::linalg::masked_matmul`` is not supported for ``half`` type.

   * - `Utilities <./reference/cpp_api/utils.html>`_
     - `cpp/include/raft/util/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/util>`_
     - Miscellaneous utility/helper functions

   * - **Common**
     - `cpp/include/raft/common/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/common>`_
     - Miscellaneous common functions used across various modules.

   * - `Random <./reference/cpp_api/random.html>`_
     - `cpp/include/raft/random/* <https://github.com/AMD-Ecosystem/hipRaft/tree/release/rocmds-26.03/cpp/include/raft/random>`_
     - Miscellaneous functions for random number generation.

       * Known issues:

          * ``raft::random::make_regression`` is not supported for the ``double`` type.

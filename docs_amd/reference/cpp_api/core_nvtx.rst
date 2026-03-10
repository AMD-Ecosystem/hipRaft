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

Profiling Ranges (ROCTX)
================================

.. role:: py(code)
   :language: c++
   :class: highlight

``#include <raft/core/nvtx.hpp>``

namespace *raft::common::nvtx*

.. doxygennamespace:: raft::common::nvtx
    :project: RAFT
    :members:
    :content-only:

.. note::

   The profiling range support in this header is backed by
   **ROCTX** (``roctx64``) rather than NVIDIA's NVTX library. The API and
   header name are kept identical for source compatibility.

   To enable profiling ranges, build hipRAFT with ``-DRAFT_NVTX=ON``. This
   links against ``roctx64`` and defines the ``NVTX_ENABLED`` compile-time
   macro. Profiling annotations can then be visualized with ROCm profiling
   tools such as `ROCm Systems Profiler <https://rocm.docs.amd.com/projects/rocprofiler-systems/en/latest/>`_
   or `rocprofv3 <https://rocm.docs.amd.com/projects/rocprofiler-sdk/en/latest/>`_.

   Without ``-DRAFT_NVTX=ON``, all ``nvtx::range`` objects compile to no-ops
   with zero overhead.

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

Resources
=========

.. role:: py(code)
   :language: c++
   :class: highlight

All resources which are specific to a computing environment like host or device are contained within, and managed by,
`raft::resources`. This design simplifies the APIs and eases user burden by making the APIs opaque by default but allowing customization based on user preference.


Vocabulary
----------

``#include <raft/core/resource/resource_types.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_types
     :project: RAFT
     :members:
     :content-only:


Device Resources
----------------

`raft::device_resources` is a convenience over using `raft::resources` directly. It provides accessor methods to retrieve
resources such as the HIP stream, stream pool, and handles to the various ROCm math libraries like hipBLAS and hipSOLVER.

``#include <raft/core/device_resources.hpp>``

namespace *raft::core*

.. doxygenclass:: raft::device_resources
    :project: RAFT
    :members:

Device Resources Manager
------------------------

While `raft::device_resources` provides a convenient way to access
device-related resources for a sequence of hipRAFT calls, it is sometimes useful
to be able to limit those resources across an entire application. For
instance, in highly multi-threaded applications, it can be helpful to limit
the total number of streams rather than relying on the default stream per
thread. `raft::device_resources_manager` offers a way to access
`raft::device_resources` instances that draw from a limited pool of
underlying device resources.

``#include <raft/core/device_resources_manager.hpp>``

namespace *raft::core*

.. doxygenstruct:: raft::device_resources_manager
    :project: RAFT
    :members:

SNMG Device Resources
---------------------

The `raft::device_resources_snmg` provides a convenient way to configure
a SNMG (single-node multi-GPU) clique for MG algorithms. It initiates
device-related resources for a set of devices. Calling RCCL-related functions
in `raft/core/resource/nccl_comm.hpp` will initialize RCCL comm on each device resource.
GPUs can be addressed and exchanges be made over multiple threads for performance.

``#include <raft/core/device_resources_snmg.hpp>``

namespace *raft::core*

.. doxygenclass:: raft::device_resources_snmg
    :project: RAFT
    :members:

Resource Functions
------------------

Comms
~~~~~

``#include <raft/core/resource/comms.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_comms
     :project: RAFT
     :members:
     :content-only:

hipBLAS Handle
~~~~~~~~~~~~~~

The cuBLAS handle resource is backed by hipBLAS. The header
name ``cublas_handle.hpp`` is retained for source compatibility with CUDA-based code.

``#include <raft/core/resource/cublas_handle.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_cublas
     :project: RAFT
     :members:
     :content-only:

hipBLASLt Handle
~~~~~~~~~~~~~~~~

The cuBLASLt handle resource is backed by hipBLASLt. The header
name ``cublaslt_handle.hpp`` is retained for source compatibility with CUDA-based code.

``#include <raft/core/resource/cublaslt_handle.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_cublaslt
     :project: RAFT
     :members:
     :content-only:

HIP Stream
~~~~~~~~~~

``#include <raft/core/resource/cuda_stream.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_cuda_stream
     :project: RAFT
     :members:
     :content-only:


HIP Stream Pool
~~~~~~~~~~~~~~~

``#include <raft/core/resource/cuda_stream_pool.hpp>``

namespace *raft::resource*

.. doxygengroup:: resource_stream_pool
    :project: RAFT
    :members:
    :content-only:

hipSOLVER Dense Handle
~~~~~~~~~~~~~~~~~~~~~~

The cuSOLVER dense handle resource is backed by hipSOLVER. The header
name ``cusolver_dn_handle.hpp`` is retained for source compatibility with CUDA-based code.

``#include <raft/core/resource/cusolver_dn_handle.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_cusolver_dn
     :project: RAFT
     :members:
     :content-only:

hipSOLVER Sparse Handle
~~~~~~~~~~~~~~~~~~~~~~~

The cuSOLVER sparse handle resource is backed by hipSOLVER. The header
name ``cusolver_sp_handle.hpp`` is retained for source compatibility with CUDA-based code.

``#include <raft/core/resource/cusolver_sp_handle.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_cusolver_sp
     :project: RAFT
     :members:
     :content-only:

hipSPARSE Handle
~~~~~~~~~~~~~~~~

The cuSPARSE handle resource is backed by hipSPARSE. The header
name ``cusparse_handle.hpp`` is retained for source compatibility with CUDA-based code.

``#include <raft/core/resource/cusparse_handle.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_cusparse
     :project: RAFT
     :members:
     :content-only:

Device ID
~~~~~~~~~

``#include <raft/core/resource/device_id.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_device_id
     :project: RAFT
     :members:
     :content-only:


Device Memory Resource
~~~~~~~~~~~~~~~~~~~~~~

``#include <raft/core/resource/device_memory_resource.hpp>``

namespace *raft::resource*

 .. doxygengroup:: device_memory_resource
     :project: RAFT
     :members:
     :content-only:

Device Properties
~~~~~~~~~~~~~~~~~

``#include <raft/core/resource/device_properties.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_device_props
     :project: RAFT
     :members:
     :content-only:

Sub Communicators
~~~~~~~~~~~~~~~~~

``#include <raft/core/resource/sub_comms.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_sub_comms
     :project: RAFT
     :members:
     :content-only:

rocThrust Exec Policy
~~~~~~~~~~~~~~~~~~~~~

The Thrust execution policy resource is backed by rocThrust. The header
name ``thrust_policy.hpp`` is retained for source compatibility with CUDA-based code.

``#include <raft/core/resource/thrust_policy.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_thrust_policy
     :project: RAFT
     :members:
     :content-only:

Custom runtime-shared resources
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A custom resource is an arbitrary default-constructible C++ class.
The consumer of the API can keep such a resource in the `raft::resources` handle.
For example, consider a function that is expected to be called repeatedly and
involves a costly kernel configuration. One can cache the kernel configuration in
a custom resource.
The cost of accessing it is one hashmap lookup.

``#include <raft/core/resource/custom_resource.hpp>``

namespace *raft::resource*

 .. doxygengroup:: resource_custom
     :project: RAFT
     :members:
     :content-only:

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

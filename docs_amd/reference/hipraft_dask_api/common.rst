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

Common
======

This page provides ``raft_dask`` class and function references for the
publicly-exposed elements of the ``raft_dask.common`` package, which
implements Multi-Node Multi-GPU (MNMG) communicator support via NCCL
and UCX/UCXX.

.. role:: py(code)
   :language: python
   :class: highlight


Communicator
############

.. autoapiclass:: raft_dask.common.comms.Comms
    :members:
    :no-index:

.. autoapifunction:: raft_dask.common.comms.local_handle
   :no-index:

.. autoapifunction:: raft_dask.common.comms.get_raft_comm_state
   :no-index:

.. autoapifunction:: raft_dask.common.comms.get_ucx
   :no-index:


UCX
###

.. autoapiclass:: raft_dask.common.ucx.UCX
    :members:
    :no-index:


NCCL
####

.. autoapiclass:: raft_dask.common.nccl.nccl
    :members:
    :no-index:

.. autoapifunction:: raft_dask.common.nccl.unique_id
   :no-index:


Comms Utilities
###############

.. autoapifunction:: raft_dask.common.comms_utils.inject_comms_on_handle
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.inject_comms_on_handle_coll_only
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_allreduce
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_reduce
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_reducescatter
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_bcast
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_allgather
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_gather
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_gatherv
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_send_recv
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_device_send_or_recv
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_device_sendrecv
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comms_device_multicast_sendrecv
   :no-index:

.. autoapifunction:: raft_dask.common.comms_utils.perform_test_comm_split
   :no-index:


Utilities
#########

.. autoapifunction:: raft_dask.common.utils.parse_host_port
   :no-index:

# MIT License
#
# Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from __future__ import annotations
import builtins as __builtins__
__all__: list[str] = ['inject_comms_on_handle', 'inject_comms_on_handle_coll_only', 'perform_test_comm_split', 'perform_test_comms_allgather', 'perform_test_comms_allreduce', 'perform_test_comms_bcast', 'perform_test_comms_device_multicast_sendrecv', 'perform_test_comms_device_send_or_recv', 'perform_test_comms_device_sendrecv', 'perform_test_comms_gather', 'perform_test_comms_gatherv', 'perform_test_comms_reduce', 'perform_test_comms_reducescatter', 'perform_test_comms_send_recv']
def inject_comms_on_handle(handle, nccl_inst, is_ucxx, ucp_worker, eps, size, rank, verbose):
    """
    inject_comms_on_handle(handle, nccl_inst, is_ucxx, ucp_worker, eps, size, rank, verbose)

    Given a handle and initialized comms, creates a comms_t instance
    and injects it into the handle.

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    nccl_inst : raft.dask.common.nccl
                Initialized nccl comm to use
    ucp_worker : size_t pointer to initialized ucp_worker_h instance
    eps: size_t pointer to array of initialized ucp_ep_h instances
    size : int
           Number of workers in cluster
    rank : int
           Rank of current worker
    """
def inject_comms_on_handle_coll_only(handle, nccl_inst, size, rank, verbose):
    """
    inject_comms_on_handle_coll_only(handle, nccl_inst, size, rank, verbose)

    Given a handle and initialized nccl comm, creates a comms_t
    instance and injects it into the handle.

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    nccl_inst : raft.dask.common.nccl
                Initialized nccl comm to use
    size : int
           Number of workers in cluster
    rank : int
           Rank of current worker
    """
def perform_test_comm_split(handle, n_colors):
    """
    perform_test_comm_split(handle, n_colors)

    Performs a p2p send/recv on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    """
def perform_test_comms_allgather(handle, root):
    """
    perform_test_comms_allgather(handle, root)

    Performs an broadcast on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    """
def perform_test_comms_allreduce(handle, root):
    """
    perform_test_comms_allreduce(handle, root)

    Performs an allreduce on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    """
def perform_test_comms_bcast(handle, root):
    """
    perform_test_comms_bcast(handle, root)

    Performs an broadcast on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    """
def perform_test_comms_device_multicast_sendrecv(handle, n_trials):
    """
    perform_test_comms_device_multicast_sendrecv(handle, n_trials)

    Performs a p2p device concurrent multicast send&recv on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    n_trilas : int
               Number of test trials
    """
def perform_test_comms_device_send_or_recv(handle, n_trials):
    """
    perform_test_comms_device_send_or_recv(handle, n_trials)

    Performs a p2p device send or recv on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    n_trilas : int
               Number of test trials
    """
def perform_test_comms_device_sendrecv(handle, n_trials):
    """
    perform_test_comms_device_sendrecv(handle, n_trials)

    Performs a p2p device concurrent send&recv on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    n_trilas : int
               Number of test trials
    """
def perform_test_comms_gather(handle, root):
    """
    perform_test_comms_gather(handle, root)

    Performs a gather on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    root : int
           Rank of the root worker
    """
def perform_test_comms_gatherv(handle, root):
    """
    perform_test_comms_gatherv(handle, root)

    Performs a gatherv on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    root : int
           Rank of the root worker
    """
def perform_test_comms_reduce(handle, root):
    """
    perform_test_comms_reduce(handle, root)

    Performs an allreduce on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    """
def perform_test_comms_reducescatter(handle, root):
    """
    perform_test_comms_reducescatter(handle, root)

    Performs an allreduce on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    """
def perform_test_comms_send_recv(handle, n_trials):
    """
    perform_test_comms_send_recv(handle, n_trials)

    Performs a p2p send/recv on the current worker

    Parameters
    ----------
    handle : raft.common.Handle
             handle containing comms_t to use
    n_trilas : int
               Number of test trials
    """
__test__: dict = {}

# MIT License
#
# Modifications Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.
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
from collections import OrderedDict
from dask_cuda.utils import nvml_device_index
from distributed.client import default_client
import logging as logging
import os as os
from pylibraft.common.handle import Handle
from raft_dask.common.comms_utils import inject_comms_on_handle
from raft_dask.common.comms_utils import inject_comms_on_handle_coll_only
from raft_dask.common.nccl import nccl
from raft_dask.common.ucx import UCX
from raft_dask.common.utils import parse_host_port
import time as time
import typing
import uuid as uuid
import warnings as warnings
__all__: list[str] = ['Comms', 'Handle', 'OrderedDict', 'UCX', 'default_client', 'get_raft_comm_state', 'get_ucx', 'inject_comms_on_handle', 'inject_comms_on_handle_coll_only', 'local_handle', 'logger', 'logging', 'nccl', 'nvml_device_index', 'os', 'parse_host_port', 'set_nccl_root', 'time', 'uuid', 'warnings']
class Comms:
    """

        Initializes and manages underlying RCCL and UCX comms handles across
        the workers of a Dask cluster. It is expected that `init()` will be
        called explicitly. It is recommended to also call `destroy()` when
        the comms are no longer needed so the underlying resources can be
        cleaned up. This class is not meant to be thread-safe.

        Examples
        --------
        .. code-block:: python

            # The following code block assumes we have wrapped a C++
            # function in a Python function called `run_algorithm`,
            # which takes a `raft::handle_t` as a single argument.
            # Once the `Comms` instance is successfully initialized,
            # the underlying `raft::handle_t` will contain an instance
            # of `raft::comms::comms_t`

            from dask_cuda import LocalCUDACluster
            from dask.distributed import Client

            from raft.dask.common import Comms, local_handle

            cluster = LocalCUDACluster()
            client = Client(cluster)

            def _use_comms(sessionId):
                return run_algorithm(local_handle(sessionId))

            comms = Comms(client=client)
            comms.init()

            futures = [client.submit(_use_comms,
                                     comms.sessionId,
                                     workers=[w],
                                     pure=False) # Don't memoize
                           for w in cb.worker_addresses]
            wait(dfs, timeout=5)

            comms.destroy()
            client.close()
            cluster.close()

    """
    valid_nccl_placements: typing.ClassVar[tuple] = ('client', 'worker', 'scheduler')
    def __del__(self):
        ...
    def __init__(self, comms_p2p = False, client = None, verbose = False, streams_per_handle = 0, nccl_root_location = 'scheduler'):
        """

                Construct a new CommsContext instance

                Parameters
                ----------
                comms_p2p : bool
                            Initialize UCX endpoints?
                client : dask.distributed.Client [optional]
                         Dask client to use
                verbose : bool
                          Print verbose logging
                nccl_root_location : string
                          Indicates where the NCCL's root node should be located.
                          ['client', 'worker', 'scheduler' (default)]


        """
    def create_nccl_uniqueid(self):
        ...
    def destroy(self):
        """

                Shuts down initialized comms and cleans up resources. This will
                be called automatically by the Comms destructor, but may be called
                earlier to save resources.

        """
    def init(self, workers = None):
        """

                Initializes the underlying comms. NCCL is required but
                UCX is only initialized if `comms_p2p == True`

                Parameters
                ----------
                workers : Sequence
                          Unique collection of workers for initializing comms.

        """
    def worker_info(self, workers):
        """

                Builds a dictionary of { (worker_address, worker_port) :
                                        (worker_rank, worker_port ) }

        """
def _func_build_handle(sessionId, streams_per_handle, verbose, dask_worker = None):
    """

        Builds a handle_t on the current worker given the initialized comms

        Parameters
        ----------
        sessionId : str id to reference state for current comms instance.
        streams_per_handle : int number of internal streams to create
        verbose : bool print verbose logging output
        dask_worker : dask_worker object
                      (Note: if called by client.run(), this is supplied by Dask
                       and not the client)

    """
def _func_build_handle_p2p(sessionId, streams_per_handle, verbose, dask_worker = None):
    """

        Builds a handle_t on the current worker given the initialized comms

        Parameters
        ----------
        sessionId : str id to reference state for current comms instance.
        streams_per_handle : int number of internal streams to create
        verbose : bool print verbose logging output
        dask_worker : dask_worker object
                      (Note: if called by client.run(), this is supplied by Dask
                       and not the client)

    """
def _func_destroy_all(sessionId, comms_p2p, verbose = False, dask_worker = None):
    ...
def _func_destroy_scheduler_session(sessionId, dask_scheduler):
    """

        Remove session date from _raft_comm_state, associated with sessionId

        Parameters
        ----------
        sessionId : session Id to be destroyed.
        dask_scheduler : dask_scheduler object
                        (Note: this is supplied by DASK, not the client)

    """
def _func_init_all(sessionId, uniqueId, comms_p2p, worker_info, verbose, streams_per_handle, dask_worker = None):
    ...
def _func_init_nccl(sessionId, uniqueId, dask_worker = None):
    """

        Initialize ncclComm_t on worker

        Parameters
        ----------
        sessionId : str
                    session identifier from a comms instance
        uniqueId : array[byte]
                   The NCCL unique Id generated from the
                   client.
        dask_worker : dask_worker object
                      (Note: if called by client.run(), this is supplied by Dask
                       and not the client)

    """
def _func_set_scheduler_as_nccl_root(sessionId, verbose, dask_scheduler):
    """

        Creates a persistent nccl uniqueId on the scheduler node.


        Parameters
        ----------
        sessionId : Associated session to attach the unique ID to.
        verbose : Indicates whether or not to emit additional information
        dask_scheduler : dask scheduler object,
                        (Note: this is supplied by DASK, not the client)

        Return
        ------
        uniqueId : byte str
                    NCCL uniqueId, associating the DASK scheduler as its root node.

    """
def _func_set_worker_as_nccl_root(sessionId, verbose, dask_worker = None):
    """

        Creates a persistent nccl uniqueId on the scheduler node.


        Parameters
        ----------
        sessionId : Associated session to attach the unique ID to.
        verbose : Indicates whether or not to emit additional information
        dask_worker : dask_worker object
                      (Note: if called by client.run(), this is supplied by Dask
                       and not the client)

        Return
        ------
        uniqueId : byte str
                    NCCL uniqueId, associating this DASK worker as its root node.

    """
def _func_store_initial_state(nworkers, sessionId, uniqueId, wid, dask_worker = None):
    ...
def _func_ucp_create_endpoints(sessionId, worker_info, dask_worker):
    """

        Runs on each worker to create ucp endpoints to all other workers

        Parameters
        ----------
        sessionId : str
                    uuid unique id for this instance
        worker_info : dict
                      Maps worker addresses to NCCL ranks & UCX ports
        dask_worker : dask_worker object
                      (Note: if called by client.run(), this is supplied by Dask
                       and not the client)

    """
def _func_ucp_listener_port(dask_worker = None):
    ...
def _func_ucp_ports(client, workers):
    ...
def _func_worker_ranks(client, workers):
    """

        For each worker connected to the client, compute a global rank which takes
        into account the NVML device index and the worker IP
        (group workers on same host and order by NVML device).
        Note that the reason for sorting was nvbug 4149999 and is presumably
        fixed afterNCCL 2.19.3.

        Parameters
        ----------
            client (object): Dask client object.
            workers (list): List of worker addresses.

    """
def _get_nvml_device_index():
    """

        Return NVML device index based on environment variable
        'CUDA_VISIBLE_DEVICES'.

    """
def _get_worker_ip(worker_address):
    """

        Extract the worker IP address from the worker address string.

        Parameters
        ----------
            worker_address (str): Full address string of the worker

    """
def get_raft_comm_state(sessionId, state_object = None, dask_worker = None):
    """

        Retrieves RAFT comms state on the scheduler node, for the given sessionId,
        creating a new session if it does not exist. If no session id is given,
        returns the state dict for all sessions.

        Parameters
        ----------
        sessionId : SessionId value to retrieve from the dask_scheduler instances
        state_object : Object (either Worker, or Scheduler) on which the raft
                       comm state will retrieved (or created)
        dask_worker : dask_worker object
                      (Note: if called by client.run(), this is supplied by Dask
                       and not the client)

        Returns
        -------
        session state : str
                        session state associated with sessionId

    """
def get_ucx(dask_worker = None):
    """

        A simple convenience wrapper to make sure UCP listener and
        endpoints are only ever assigned once per worker.

        Parameters
        ----------
        dask_worker : dask_worker object
                      (Note: if called by client.run(), this is supplied by Dask
                       and not the client)

    """
def local_handle(sessionId, dask_worker = None):
    """

        Simple helper function for retrieving the local handle_t instance
        for a comms session on a worker.

        Parameters
        ----------
        sessionId : str
                    session identifier from an initialized comms instance
        dask_worker : dask_worker object
                      (Note: if called by client.run(), this is supplied by Dask
                       and not the client)

        Returns
        -------
        handle : raft.Handle or None

    """
def set_nccl_root(sessionId, state_object):
    ...
logger: logging.Logger  # value = <Logger raft_dask.common.comms (INFO)>

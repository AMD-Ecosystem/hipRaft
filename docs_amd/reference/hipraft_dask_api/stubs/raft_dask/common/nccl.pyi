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
__all__: list[str] = ['NCCL_UNIQUE_ID_BYTES', 'nccl', 'unique_id']
class nccl:
    """

        A NCCL/RCCL wrapper for initializing and closing NCCL/RCCL comms
        in Python. RCCL is the AMD implementation of NCCL.

    """
    @staticmethod
    def __new__(type, *args, **kwargs):
        """
        Create and return a new object.  See help(type) for accurate signature.
        """
    @staticmethod
    def __reduce__(*args, **kwargs):
        """
        nccl.__reduce_cython__(self)
        """
    @staticmethod
    def __setstate__(*args, **kwargs):
        """
        nccl.__setstate_cython__(self, __pyx_state)
        """
    @staticmethod
    def get_unique_id():
        """
        nccl.get_unique_id()

        Returns a new nccl unique id

        Returns
        -------
        nccl unique id : str
        """
    def abort(self):
        """
        nccl.abort(self)

        Call abort on the underlying nccl comm
        """
    def cu_device(self):
        """
        nccl.cu_device(self)

        Get the device backing the underlying comm

        Returns
        -------
        device id : int
        """
    def destroy(self):
        """
        nccl.destroy(self)

        Call destroy on the underlying NCCL comm
        """
    def get_comm(self):
        """
        nccl.get_comm(self)

        Returns the underlying nccl comm in a size_t (similar to void*).
        This can be safely typecasted from size_t into ncclComm_t*

        Returns
        -------
        ncclComm_t instance pointer : size_t
        """
    def init(self, nranks, commId, rank):
        """
        nccl.init(self, nranks, commId, rank)

        Construct a nccl-py object

        Parameters
        ----------
        nranks : int size of clique
        commId : string unique id from client
        rank : int rank of current worker
        """
    def user_rank(self):
        """
        nccl.user_rank(self)

        Get the rank id of the current comm

        Returns
        -------
        rank : int
        """
def __reduce_cython__(self):
    """
    nccl.__reduce_cython__(self)
    """
def __setstate_cython__(self, __pyx_state):
    """
    nccl.__setstate_cython__(self, __pyx_state)
    """
def unique_id():
    """
    unique_id()

    Returns a new ncclUniqueId converted to a
    character array that can be safely serialized
    and shared to a remote worker.

    Returns
    -------
    128-byte unique id : str
    """
NCCL_UNIQUE_ID_BYTES: int = 128
__test__: dict = {}

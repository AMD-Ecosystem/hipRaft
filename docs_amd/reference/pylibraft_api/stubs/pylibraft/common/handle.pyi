from __future__ import annotations
import builtins as __builtins__
import functools as functools
from pylibraft.common.cuda import CudaRuntimeError
__all__: list[str] = ['CudaRuntimeError', 'DeviceResources', 'DeviceResourcesSNMG', 'Handle', 'auto_sync_handle', 'functools']
class DeviceResources:
    """

        DeviceResources is a lightweight python wrapper around the corresponding
        C++ class of device_resources exposed by RAFT's C++ interface. Refer to
        the header file raft/core/device_resources.hpp for interface level
        details of this struct

        Parameters
        ----------
        stream : Optional stream to use for ordering CUDA instructions
                 Accepts pylibraft.common.Stream() or uintptr_t (cudaStream_t)

        Examples
        --------

        Basic usage:

        >>> from pylibraft.common import Stream, DeviceResources
        >>> stream = Stream()
        >>> handle = DeviceResources(stream)
        >>>
        >>> # call algos here
        >>>
        >>> # final sync of all work launched in the stream of this handle
        >>> # this is same as `raft.cuda.Stream.sync()` call, but safer in case
        >>> # the default stream inside the `device_resources` is being used
        >>> handle.sync()
        >>> del handle  # optional!

        Using a cuPy stream with RAFT device_resources:

        >>> import cupy
        >>> from pylibraft.common import Stream, DeviceResources
        >>>
        >>> cupy_stream = cupy.cuda.Stream()
        >>> handle = DeviceResources(stream=cupy_stream.ptr)

        Using a RAFT stream with CuPy ExternalStream:

        >>> import cupy
        >>> from pylibraft.common import Stream
        >>>
        >>> raft_stream = Stream()
        >>> cupy_stream = cupy.cuda.ExternalStream(raft_stream.get_ptr())

    """
    @staticmethod
    def __new__(type, *args, **kwargs):
        """
        Create and return a new object.  See help(type) for accurate signature.
        """
    @staticmethod
    def __reduce_cython__(*args, **kwargs):
        """
        DeviceResources.__reduce_cython__(self)
        """
    @staticmethod
    def __setstate_cython__(*args, **kwargs):
        """
        DeviceResources.__setstate_cython__(self, __pyx_state)
        """
    def __getstate__(self):
        """
        DeviceResources.__getstate__(self)
        """
    def __setstate__(self, state):
        """
        DeviceResources.__setstate__(self, state)
        """
    def getHandle(self):
        """
        DeviceResources.getHandle(self)

                Return the pointer to the underlying raft::device_resources
                instance as a size_t

        """
    def sync(self):
        """
        DeviceResources.sync(self)

                Issues a sync on the stream set for this instance.

        """
class DeviceResourcesSNMG:
    """

        DeviceResourcesSNMG manages multi-GPU resources
        in a single-node setup using RAFT's device_resources_snmg. Refer to
        the header file raft/core/device_resources_snmg.hpp for interface level
        details of this struct
        Parameters
        ----------
        device_ids : Optional list to specify which devices will be used
        Examples
        --------
        Basic usage:
        >>> from pylibraft.common import DeviceResourcesSNMG
        >>>
        >>> # to use GPU IDs 0,1,2,3 on machine
        >>> # handle = DeviceResourcesSNMG([0,1,2,3])
        >>>
        >>> # to use all GPUs on machine
        >>> handle = DeviceResourcesSNMG()

    """
    @staticmethod
    def __new__(type, *args, **kwargs):
        """
        Create and return a new object.  See help(type) for accurate signature.
        """
    @staticmethod
    def __reduce_cython__(*args, **kwargs):
        """
        DeviceResourcesSNMG.__reduce_cython__(self)
        """
    @staticmethod
    def __setstate_cython__(*args, **kwargs):
        """
        DeviceResourcesSNMG.__setstate_cython__(self, __pyx_state)
        """
    def __getstate__(self):
        """
        DeviceResourcesSNMG.__getstate__(self)
        """
    def __setstate__(self, state):
        """
        DeviceResourcesSNMG.__setstate__(self, state)
        """
    def getHandle(self):
        """
        DeviceResourcesSNMG.getHandle(self)

                Return the pointer to the underlying raft::device_resources_snmg
                instance as a size_t

        """
    def sync(self):
        """
        DeviceResourcesSNMG.sync(self)

                Issues a sync on the stream set for this instance.

        """
class Handle(DeviceResources):
    """

        Handle is a lightweight python wrapper around the corresponding
        C++ class of handle_t exposed by RAFT's C++ interface. Refer to
        the header file raft/core/handle.hpp for interface level
        details of this struct

        Note: This API is officially deprecated in favor of DeviceResources
        and will be removed in a future release.

        Parameters
        ----------
        stream : Optional stream to use for ordering CUDA instructions
                Accepts pylibraft.common.Stream() or uintptr_t (cudaStream_t)

        Examples
        --------

        Basic usage:

        >>> from pylibraft.common import Stream, Handle
        >>> stream = Stream()
        >>> handle = Handle(stream)
        >>>
        >>> # call algos here
        >>>
        >>> # final sync of all work launched in the stream of this handle
        >>> # this is same as `raft.cuda.Stream.sync()` call, but safer in case
        >>> # the default stream inside the `handle_t` is being used
        >>> handle.sync()
        >>> del handle  # optional!

        Using a cuPy stream with RAFT device_resources:

        >>> import cupy
        >>> from pylibraft.common import Stream, Handle
        >>>
        >>> cupy_stream = cupy.cuda.Stream()
        >>> handle = Handle(stream=cupy_stream.ptr)

        Using a RAFT stream with CuPy ExternalStream:

        >>> import cupy
        >>> from pylibraft.common import Stream
        >>>
        >>> raft_stream = Stream()
        >>> cupy_stream = cupy.cuda.ExternalStream(raft_stream.get_ptr())


    """
    @staticmethod
    def __new__(type, *args, **kwargs):
        """
        Create and return a new object.  See help(type) for accurate signature.
        """
    @staticmethod
    def __reduce_cython__(*args, **kwargs):
        """
        Handle.__reduce_cython__(self)
        """
    @staticmethod
    def __setstate_cython__(*args, **kwargs):
        """
        Handle.__setstate_cython__(self, __pyx_state)
        """
    def __getstate__(self):
        """
        Handle.__getstate__(self)
        """
    def __setstate__(self, state):
        """
        Handle.__setstate__(self, state)
        """
def __reduce_cython__(self):
    """
    DeviceResourcesSNMG.__reduce_cython__(self)
    """
def __setstate_cython__(self, __pyx_state):
    """
    DeviceResourcesSNMG.__setstate_cython__(self, __pyx_state)
    """
def auto_sync_handle(f):
    """
    auto_sync_handle(f)
    Decorator to automatically call sync on a raft handle when
        it isn't passed to a function.

        When a handle=None is passed to the wrapped function, this decorator
        will automatically create a default handle for the function, and
        call sync on that handle when the function exits.

        This will also insert the appropriate docstring for the handle parameter

    """
_HANDLE_PARAM_DOCSTRING: str = "handle : Optional RAFT resource handle for reusing CUDA resources.\n        If a handle isn't supplied, CUDA resources will be\n        allocated inside this function and synchronized before the\n        function exits. If a handle is supplied, you will need to\n        explicitly synchronize yourself by calling `handle.sync()`\n        before accessing the output."
__test__: dict = {}

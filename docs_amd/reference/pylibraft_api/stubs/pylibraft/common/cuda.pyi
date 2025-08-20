from __future__ import annotations
import builtins as __builtins__
import typing
__all__: list[str] = ['CudaRuntimeError', 'Stream']
class CudaRuntimeError(RuntimeError):
    def __init__(self, extraMsg = None):
        """
        CudaRuntimeError.__init__(self, extraMsg=None)
        """
class Stream:
    """

        Stream represents a thin-wrapper around cudaStream_t and its operations.

        Examples
        --------

        >>> from pylibraft.common.cuda import Stream
        >>> stream = Stream()
        >>> stream.sync()
        >>> del stream  # optional!

    """
    __pyx_vtable__: typing.ClassVar[typing.Any]  # value = <capsule object>
    @staticmethod
    def __new__(type, *args, **kwargs):
        """
        Create and return a new object.  See help(type) for accurate signature.
        """
    @staticmethod
    def __reduce__(*args, **kwargs):
        """
        Stream.__reduce_cython__(self)
        """
    @staticmethod
    def __setstate__(*args, **kwargs):
        """
        Stream.__setstate_cython__(self, __pyx_state)
        """
    def get_ptr(self):
        """
        Stream.get_ptr(self)

                Return the uintptr_t pointer of the underlying cudaStream_t handle

        """
    def sync(self):
        """
        Stream.sync(self)

                Synchronize on the cudastream owned by this object. Note that this
                could raise exception due to issues with previous asynchronous
                launches

        """
def __reduce_cython__(self):
    """
    Stream.__reduce_cython__(self)
    """
def __setstate_cython__(self, __pyx_state):
    """
    Stream.__setstate_cython__(self, __pyx_state)
    """
__test__: dict = {}

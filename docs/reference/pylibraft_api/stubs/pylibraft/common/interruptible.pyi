from __future__ import annotations
import builtins as __builtins__
import contextlib as contextlib
import signal as signal
__all__: list[str] = ['contextlib', 'cuda_interruptible', 'cuda_yield', 'signal', 'synchronize']
def cuda_interruptible(*args, **kwds):
    """
    cuda_interruptible()

        Temporarily install a keyboard interrupt handler (Ctrl+C)
        that cancels the enclosed interruptible C++ thread.

        Use this on a long-running C++ function imported via cython:

        >>> with cuda_interruptible():
        >>>     my_long_running_function(...)

        It's also recommended to release the GIL during the call, to
        make sure the handler has a chance to run:

        >>> with cuda_interruptible():
        >>>     with nogil:
        >>>         my_long_running_function(...)

    """
def cuda_yield():
    """
    cuda_yield()

        Check for an asynchronously received interrupted_exception.
        Raises the exception if a user pressed Ctrl+C within a
        `with cuda_interruptible()` block before.

    """
def synchronize(stream: Stream):
    """
    synchronize(Stream stream: Stream)

        Same as cudaStreamSynchronize, but can be interrupted
        if called within a `with cuda_interruptible()` block.

    """
__test__: dict = {'cuda_interruptible (line 33)': "\n    Temporarily install a keyboard interrupt handler (Ctrl+C)\n    that cancels the enclosed interruptible C++ thread.\n\n    Use this on a long-running C++ function imported via cython:\n\n    >>> with cuda_interruptible():\n    >>>     my_long_running_function(...)\n\n    It's also recommended to release the GIL during the call, to\n    make sure the handler has a chance to run:\n\n    >>> with cuda_interruptible():\n    >>>     with nogil:\n    >>>         my_long_running_function(...)\n    "}

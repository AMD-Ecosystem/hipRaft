from __future__ import annotations
import builtins as __builtins__
import numpy as np
from pylibraft.common.cai_wrapper import cai_wrapper
from pylibraft.common.handle import Handle
from pylibraft.common.handle import auto_sync_handle
__all__: list[str] = ['Handle', 'auto_sync_handle', 'cai_wrapper', 'np', 'rmat']
def rmat(*args, handle = None, **kwargs):
    """
    rmat(out, theta, r_scale, c_scale, seed=12345, handle=None)

        Generate RMAT adjacency list based on the input distribution.

        Parameters
        ----------

        out:
            CUDA array interface compliant matrix shape (n_edges, 2). This will
            contain the src/dst node ids stored consecutively like a pair.
        theta:
            CUDA array interface compliant matrix shape
            (max(r_scale, c_scale) * 4) This stores the probability distribution
            at each RMAT level
        r_scale: int
            log2 of number of source nodes
        c_scale: int
            log2 of number of destination nodes
        seed: int
            random seed used for reproducibility
        handle : Optional RAFT resource handle for reusing CUDA resources.
            If a handle isn't supplied, CUDA resources will be
            allocated inside this function and synchronized before the
            function exits. If a handle is supplied, you will need to
            explicitly synchronize yourself by calling `handle.sync()`
            before accessing the output.

        Examples
        --------

        >>> import cupy as cp

        >>> from pylibraft.common import Handle
        >>> from pylibraft.random import rmat

        >>> n_edges = 5000
        >>> r_scale = 16
        >>> c_scale = 14
        >>> theta_len = max(r_scale, c_scale) * 4

        >>> out = cp.empty((n_edges, 2), dtype=cp.int32)
        >>> theta = cp.random.random_sample(theta_len, dtype=cp.float32)

        >>> # A single RAFT handle can optionally be reused across
        >>> # pylibraft functions.
        >>> handle = Handle()

        >>> rmat(out, theta, r_scale, c_scale, handle=handle)

        >>> # pylibraft functions are often asynchronous so the
        >>> # handle needs to be explicitly synchronized
        >>> handle.sync()

    """
__test__: dict = {'rmat (line 79)': '\n    Generate RMAT adjacency list based on the input distribution.\n\n    Parameters\n    ----------\n\n    out:\n        CUDA array interface compliant matrix shape (n_edges, 2). This will\n        contain the src/dst node ids stored consecutively like a pair.\n    theta:\n        CUDA array interface compliant matrix shape\n        (max(r_scale, c_scale) * 4) This stores the probability distribution\n        at each RMAT level\n    r_scale: int\n        log2 of number of source nodes\n    c_scale: int\n        log2 of number of destination nodes\n    seed: int\n        random seed used for reproducibility\n    {handle_docstring}\n\n    Examples\n    --------\n\n    >>> import cupy as cp\n\n    >>> from pylibraft.common import Handle\n    >>> from pylibraft.random import rmat\n\n    >>> n_edges = 5000\n    >>> r_scale = 16\n    >>> c_scale = 14\n    >>> theta_len = max(r_scale, c_scale) * 4\n\n    >>> out = cp.empty((n_edges, 2), dtype=cp.int32)\n    >>> theta = cp.random.random_sample(theta_len, dtype=cp.float32)\n\n    >>> # A single RAFT handle can optionally be reused across\n    >>> # pylibraft functions.\n    >>> handle = Handle()\n\n    >>> rmat(out, theta, r_scale, c_scale, handle=handle)\n\n    >>> # pylibraft functions are often asynchronous so the\n    >>> # handle needs to be explicitly synchronized\n    >>> handle.sync()\n   '}

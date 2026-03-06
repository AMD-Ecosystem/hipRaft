from __future__ import annotations
import builtins as __builtins__
import cupy as cp
import numpy as np
from pylibraft.common.cai_wrapper import cai_wrapper
from pylibraft.common.device_ndarray import device_ndarray
from pylibraft.common.handle import Handle
from pylibraft.common.handle import auto_sync_handle
__all__: list[str] = ['Handle', 'auto_sync_handle', 'cai_wrapper', 'cp', 'device_ndarray', 'eigsh', 'np']
def eigsh(*args, handle = None, **kwargs):
    """
    eigsh(A, k=6, which=u'LM', v0=None, ncv=None, maxiter=None, tol=0, seed=None, handle=None)

        Find ``k`` eigenvalues and eigenvectors of the real symmetric square
        matrix or complex Hermitian matrix ``A``.

        Solves ``Ax = wx``, the standard eigenvalue problem for ``w`` eigenvalues
        with corresponding eigenvectors ``x``.

        Args:
            a (spmatrix): A symmetric square sparse CSR matrix with
                dimension ``(n, n)``. ``a`` must be of type
                :class:`cupyx.scipy.sparse._csr.csr_matrix`
            k (int): The number of eigenvalues and eigenvectors to compute. Must be
                ``1 <= k < n``.
            which (str): 'LM' or 'LA' or 'SA'.
                'LM': finds ``k`` largest (in magnitude) eigenvalues.
                'LA': finds ``k`` largest (algebraic) eigenvalues.
                'SA': finds ``k`` smallest (algebraic) eigenvalues.
                'SM': finds ``k`` smallest (in magnitude) eigenvalues.
            v0 (ndarray): Starting vector for iteration. If ``None``, a random
                unit vector is used.
            ncv (int): The number of Lanczos vectors generated. Must be
                ``k + 1 < ncv < n``. If ``None``, default value is used.
            maxiter (int): Maximum number of Lanczos update iterations.
                If ``None``, default value is used.
            tol (float): Tolerance for residuals ``||Ax - wx||``. If ``0``, machine
                precision is used.

        Returns:
            tuple:
                It returns ``w`` and ``x``
                where ``w`` is eigenvalues and ``x`` is eigenvectors.

        .. seealso::
            :func:`scipy.sparse.linalg.eigsh`
            :func:`cupyx.scipy.sparse.linalg.eigsh`

        .. note::
            This function uses the thick-restart Lanczos methods
            (https://sdm.lbl.gov/~kewu/ps/trlan.html).


    """
__test__: dict = {}

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
    eigsh(A, k=6, which='LM', v0=None, ncv=None, maxiter=None, tol=0, seed=None, handle=None)
    
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

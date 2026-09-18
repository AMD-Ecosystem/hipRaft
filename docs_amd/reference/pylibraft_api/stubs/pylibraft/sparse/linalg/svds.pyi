# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
#

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
from cupyx.scipy import sparse as cupy_sparse
import numpy as np
from pylibraft.common.cai_wrapper import cai_wrapper
from pylibraft.common.device_ndarray import device_ndarray
from pylibraft.common.handle import Handle
from pylibraft.common.handle import auto_sync_handle
import warnings as warnings
__all__: list[str] = ['Handle', 'auto_sync_handle', 'cai_wrapper', 'cp', 'cupy_sparse', 'device_ndarray', 'np', 'svds', 'warnings']
def svds(*args, handle = None, **kwargs):
    """
    svds(A, k=6, n_oversamples=10, n_power_iters=2, seed=None, return_singular_vectors=True, handle=None)
    
    Compute the largest ``k`` singular values and corresponding singular
    vectors of a sparse matrix using randomized SVD.
    
    Computes the truncated SVD: ``A ~ U @ diag(S) @ Vt``.
    
    Args:
        A (cupyx.scipy.sparse.csr_matrix): Sparse CSR matrix of shape
            ``(m, n)``. Must be of type
            :class:`cupyx.scipy.sparse.csr_matrix`.
        k (int): Number of singular values and vectors to compute. Must be
            ``1 <= k < min(m, n)``. Default 6.
        n_oversamples (int): Number of extra random vectors for better
            approximation. Total subspace dimension is ``k + n_oversamples``.
            Default 10.
        n_power_iters (int): Number of power iteration passes. More
            iterations improve accuracy for matrices with slowly decaying
            singular values. Default 2.
        seed (int or None): Random seed for reproducibility. If ``None``,
            a non-deterministic seed is used.
        return_singular_vectors (bool or {"u", "vh"}): Controls which
            singular vectors are returned (matches
            :func:`scipy.sparse.linalg.svds`).
    
            - ``True`` (default): return ``(U, S, Vt)``.
            - ``False``: skip both vector matrices, return ``(None, S, None)``.
            - ``"u"``: skip ``Vt``, return ``(U, S, None)``.
            - ``"vh"``: skip ``U``, return ``(None, S, Vt)``.
    
            Skipping a side avoids the corresponding output buffer and
            final matrix multiplication.
        handle: RAFT resource handle. If ``None``, a default is created.
    
    Returns:
        tuple:
            ``(U, S, Vt)`` where ``U`` is left singular vectors ``(m, k)``,
            ``S`` is singular values ``(k,)`` in descending order, and
            ``Vt`` is right singular vectors ``(k, n)``. ``U`` and/or ``Vt``
            may be ``None`` depending on ``return_singular_vectors``.
    
    .. seealso::
        :func:`scipy.sparse.linalg.svds`
    
    .. note::
        This function uses randomized SVD (Halko et al. 2009) with
        CholeskyQR2 orthogonalization (Tomas et al. 2024) for efficient
        GPU execution.
    """
__test__: dict = {}

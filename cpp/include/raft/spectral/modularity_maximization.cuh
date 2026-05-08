/*
 * SPDX-FileCopyrightText: Copyright (c) 2020-2026, NVIDIA CORPORATION.
 * SPDX-License-Identifier: Apache-2.0
 */

// MIT License
//
// Modifications Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifndef __MODULARITY_MAXIMIZATION_H
#define __MODULARITY_MAXIMIZATION_H

#pragma once

#include <raft/core/detail/macros.hpp>
#include <raft/spectral/detail/modularity_maximization.hpp>

#include <tuple>

namespace RAFT_EXPORT raft {
namespace spectral {

/**
 * @defgroup spectral_modularity Spectral modularity maximization
 * @{
 */

//===================================================
// Analysis of graph modularity
// =========================================================

/// Compute modularity
/** This function determines the modularity based on a graph and cluster assignments
 *  @param handle raft handle for managing expensive resources
 *  @param csr_m Weighted graph in CSR format
 *  @param nClusters Number of clusters.
 *  @param clusters (Input, device memory, n entries) Cluster assignments.
 *  @param modularity On exit, modularity
 */
template <typename vertex_t, typename weight_t, typename nnz_t>
void analyzeModularity(raft::resources const& handle,
                       matrix::sparse_matrix_t<vertex_t, weight_t, nnz_t> const& csr_m,
                       vertex_t nClusters,
                       vertex_t const* __restrict__ clusters,
                       weight_t& modularity)
{
  raft::spectral::detail::analyzeModularity<vertex_t, weight_t, nnz_t>(
    handle, csr_m, nClusters, clusters, modularity);
}

/** @} */

}  // namespace spectral
}  // namespace RAFT_EXPORT raft

#endif

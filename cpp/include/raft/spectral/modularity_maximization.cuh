/*
 * Copyright (c) 2020-2024, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// MIT License
//
// Modifications Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.
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

#include <raft/spectral/detail/modularity_maximization.hpp>

#include <tuple>

namespace raft {
namespace spectral {

/**
 * @defgroup spectral_modularity Spectral modularity maximization
 * @{
 */

// =========================================================
// Spectral modularity_maximization
// =========================================================

/** Compute partition for a weighted undirected graph. This
 *  partition attempts to minimize the cost function:
 *    Cost = \f$sum_i\f$ (Edges cut by ith partition)/(Vertices in ith partition)
 *
 *  @param handle raft handle for managing expensive resources
 *  @param csr_m Weighted graph in CSR format
 *  @param eigen_solver Eigensolver implementation
 *  @param cluster_solver Cluster solver implementation
 *  @param clusters (Output, device memory, n entries) Partition
 *    assignments.
 *  @param eigVals Output eigenvalue array pointer on device
 *  @param eigVecs Output eigenvector array pointer on device
 *  @return statistics: number of eigensolver iterations, .
 */
template <typename vertex_t,
          typename weight_t,
          typename nnz_t,
          typename EigenSolver,
          typename ClusterSolver>
std::tuple<vertex_t, weight_t, vertex_t> modularity_maximization(
  raft::resources const& handle,
  matrix::sparse_matrix_t<vertex_t, weight_t, nnz_t> const& csr_m,
  EigenSolver const& eigen_solver,
  ClusterSolver const& cluster_solver,
  vertex_t* __restrict__ clusters,
  weight_t* eigVals,
  weight_t* eigVecs)
{
  return raft::spectral::detail::
    modularity_maximization<vertex_t, weight_t, nnz_t, EigenSolver, ClusterSolver>(
      handle, csr_m, eigen_solver, cluster_solver, clusters, eigVals, eigVecs);
}
//===================================================
// Analysis of graph partition
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
}  // namespace raft

#endif

/*
 * Copyright (c) 2024, NVIDIA CORPORATION.
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
// Modifications Copyright (C) 2025 Advanced Micro Devices, Inc. All rights reserved.
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

#pragma once

#include <raft/core/device_mdarray.hpp>
#include <raft/core/device_mdspan.hpp>
#include <raft/core/logger.hpp>
#include <raft/core/resource/device_memory_resource.hpp>
#include <raft/core/resources.hpp>
#include <raft/matrix/gather.cuh>
#include <raft/random/rng.cuh>
#include <raft/util/cuda_utils.cuh>
#include <raft/util/cudart_utils.hpp>

namespace raft::matrix::detail {

template <typename T, typename IdxT = int64_t>
void gather_host_path(raft::resources const& res,
                      const T* input,
                      IdxT n_dim,
                      IdxT ld,
                      IdxT n_rows_input,
                      raft::device_matrix_view<T, IdxT> output,
                      raft::device_vector<IdxT, IdxT> const& train_indices)
{
#ifdef __HIP_PLATFORM_AMD__
  // (HIP/AMD) In the code path below when the input dataset is on the host, raft::matrix::gather
  // utilizes pinned memory as a staging area before gathering rows of the input dataset to the
  // output. This is done to avoid the overhead of copying the entire input dataset to the device.
  // However, the pinned memory usage on AMD systems with unified memory architectures like the
  // MI300A leads to incorrect results. The workaround is to allocate a device buffer and copy the
  // input dataset to it before calling raft::matrix::gather.
  // See internal issue 129.
  int current_device = -1;
  RAFT_CUDA_TRY(hipGetDevice(&current_device));
  hipDeviceProp_t device_prop{};
  RAFT_CUDA_TRY(hipGetDeviceProperties(&device_prop, current_device));
  if (device_prop.unifiedAddressing) {
    rmm::device_uvector<T> backing_storage(n_rows_input * ld,
                                           raft::resource::get_cuda_stream(res),
                                           raft::resource::get_large_workspace_resource(res));
    raft::copy(
      backing_storage.data(), input, n_rows_input * ld, raft::resource::get_cuda_stream(res));
    auto device_dataset = raft::make_device_strided_matrix_view<const T, IdxT>(
      backing_storage.data(), n_rows_input, n_dim, ld);
    raft::matrix::gather(
      res, device_dataset, raft::make_const_mdspan(train_indices.view()), output);
  } else {
    // (HIP/AMD) Not using unified addressing, should be safe to use the host path
    auto dataset =
      raft::make_host_strided_matrix_view<const T, IdxT>(input, n_rows_input, n_dim, ld);
    raft::matrix::detail::gather(res, dataset, make_const_mdspan(train_indices.view()), output);
  }
#else
  auto dataset = raft::make_host_strided_matrix_view<const T, IdxT>(input, n_rows_input, n_dim, ld);
  raft::matrix::detail::gather(res, dataset, make_const_mdspan(train_indices.view()), output);
#endif
}

/** Select rows randomly from input and copy to output. */
template <typename T, typename IdxT = int64_t>
void sample_rows(raft::resources const& res,
                 random::RngState random_state,
                 const T* input,
                 IdxT ld,
                 IdxT n_rows_input,
                 raft::device_matrix_view<T, IdxT> output)
{
  IdxT n_dim     = output.extent(1);
  IdxT n_samples = output.extent(0);

  raft::device_vector<IdxT, IdxT> train_indices =
    raft::random::excess_subsample<IdxT, int64_t>(res, random_state, n_rows_input, n_samples);

  cudaPointerAttributes attr;
  RAFT_CUDA_TRY(cudaPointerGetAttributes(&attr, input));
  // We can have both valid host and device pointers (systems with HMM or ATS).
  // In that case the dataset can be larger than GPU memory and gathering on host is preferred.
  if (attr.hostPointer != nullptr) {
    T* ptr = reinterpret_cast<T*>(attr.hostPointer);
    gather_host_path(res, ptr, n_dim, ld, n_rows_input, output, train_indices);
  } else if (attr.devicePointer != nullptr) {
    T* ptr = reinterpret_cast<T*>(attr.devicePointer);
    auto dataset =
      raft::make_device_strided_matrix_view<const T, IdxT>(ptr, n_rows_input, n_dim, ld);
    raft::matrix::gather(res, dataset, raft::make_const_mdspan(train_indices.view()), output);
  } else {
    // For older driver versions it can happen that both device and host pointers in `attr` are
    // invalid. We use the original host pointer in this case.
    gather_host_path(res, input, n_dim, ld, n_rows_input, output, train_indices);
  }
}

template <typename T, typename IdxT = int64_t>
void sample_rows(raft::resources const& res,
                 random::RngState random_state,
                 const T* input,
                 IdxT n_rows_input,
                 raft::device_matrix_view<T, IdxT> output)
{
  IdxT n_dim = output.extent(1);
  sample_rows<T, IdxT>(res, random_state, input, n_dim, n_rows_input, output);
}
}  // namespace raft::matrix::detail

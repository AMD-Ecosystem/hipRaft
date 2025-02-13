/*
 * Copyright (c) 2021-2024, NVIDIA CORPORATION.
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
/*
 * Modifications Copyright (c) 2024-2025 Advanced Micro Devices, Inc.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#pragma once

#include <raft/linalg/eltwise.cuh>
#include <raft/linalg/reduce.cuh>
#include <raft/util/cuda_utils.cuh>

#ifdef __HIP_PLATFORM_AMD__
#include <hipcub/hipcub.hpp>
namespace cub = hipcub;
#else
#include <cub/cub.cuh>
#endif

namespace raft {
namespace stats {
namespace detail {

template <typename Type, typename IdxType = int>
void mean(Type* mu, const Type* data, IdxType D, IdxType N, bool rowMajor, cudaStream_t stream)
{
  Type ratio = Type(1) / Type(N);
  raft::linalg::reduce(mu,
                       data,
                       D,
                       N,
                       Type(0),
                       rowMajor,
                       false,
                       stream,
                       false,
                       raft::identity_op(),
                       raft::add_op(),
                       raft::mul_const_op<Type>(ratio));
}

template <typename Type, typename IdxType = int>
[[deprecated]] void mean(
  Type* mu, const Type* data, IdxType D, IdxType N, bool sample, bool rowMajor, cudaStream_t stream)
{
  Type ratio = Type(1) / ((sample) ? Type(N - 1) : Type(N));
  raft::linalg::reduce(mu,
                       data,
                       D,
                       N,
                       Type(0),
                       rowMajor,
                       false,
                       stream,
                       false,
                       raft::identity_op(),
                       raft::add_op(),
                       raft::mul_const_op<Type>(ratio));
}

}  // namespace detail
}  // namespace stats
}  // namespace raft

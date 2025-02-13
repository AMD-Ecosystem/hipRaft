/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file thirdparty/LICENSES/LICENSE.faiss
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

#ifdef __HIP_PLATFORM_AMD__
#include <raft/cuda_runtime.h>

#include <hip/hip_fp16.h>
#else
#include <cuda.h>
#include <cuda_fp16.h>
#endif

namespace raft::neighbors::detail::faiss_select {

template <typename T>
struct Comparator {
  __device__ static inline bool lt(T a, T b) { return a < b; }

  __device__ static inline bool gt(T a, T b) { return a > b; }
};

template <>
struct Comparator<half> {
  __device__ static inline bool lt(half a, half b) { return __hlt(a, b); }

  __device__ static inline bool gt(half a, half b) { return __hgt(a, b); }
};

}  // namespace raft::neighbors::detail::faiss_select

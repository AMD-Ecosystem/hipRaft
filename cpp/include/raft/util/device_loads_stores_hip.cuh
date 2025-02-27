/*
 * Copyright (c) 2023-2024, NVIDIA CORPORATION.
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
// Copyright (c) 2025 Advanced Micro Devices, Inc.
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

#include <raft/core/device_span.hpp>
#include <raft/util/cuda_dev_essentials.cuh>  // DI

#include <hip/hip_fp16.h>
#include <rocprim/rocprim.hpp>

#include <cstdint>  // uintX_t

namespace raft {

/**
 * @defgroup SmemStores Shared memory store operations
 * @{
 * @brief Stores to shared memory (LDS)
 *
 * @param[in] addr  memory address
 * @param[in]  x    data to be stored at this address
 */
DI void sts(uint8_t* addr, const uint8_t& x) { addr[0] = x; }
DI void sts(uint8_t* addr, const uint8_t (&x)[1]) { addr[0] = x[0]; }
DI void sts(uint8_t* addr, const uint8_t (&x)[2])
{
  addr[0] = x[0];
  addr[1] = x[1];
}
DI void sts(uint8_t* addr, const uint8_t (&x)[4])
{
  addr[0] = x[0];
  addr[1] = x[1];
  addr[2] = x[2];
  addr[3] = x[3];
}
DI void sts(int8_t* addr, const int8_t& x) { addr[0] = x; }
DI void sts(int8_t* addr, const int8_t (&x)[1]) { addr[0] = x[0]; }
DI void sts(int8_t* addr, const int8_t (&x)[2])
{
  addr[0] = x[0];
  addr[1] = x[1];
}
DI void sts(int8_t* addr, const int8_t (&x)[4])
{
  addr[0] = x[0];
  addr[1] = x[1];
  addr[2] = x[2];
  addr[3] = x[3];
}
DI void sts(uint32_t* addr, const uint32_t& x) { addr[0] = x; }
DI void sts(uint32_t* addr, const uint32_t (&x)[1]) { addr[0] = x[0]; }
DI void sts(uint32_t* addr, const uint32_t (&x)[2])
{
  addr[0] = x[0];
  addr[1] = x[1];
}
DI void sts(uint32_t* addr, const uint32_t (&x)[4])
{
  addr[0] = x[0];
  addr[1] = x[1];
  addr[2] = x[2];
  addr[3] = x[3];
}
DI void sts(int32_t* addr, const int32_t& x) { addr[0] = x; }
DI void sts(int32_t* addr, const int32_t (&x)[1]) { addr[0] = x[0]; }
DI void sts(int32_t* addr, const int32_t (&x)[2])
{
  addr[0] = x[0];
  addr[1] = x[1];
}
DI void sts(int32_t* addr, const int32_t (&x)[4])
{
  addr[0] = x[0];
  addr[1] = x[1];
  addr[2] = x[2];
  addr[3] = x[3];
}
DI void sts(half* addr, const half& x) { addr[0] = x; }
DI void sts(half* addr, const half (&x)[1]) { addr[0] = x[0]; }
DI void sts(half* addr, const half (&x)[2])
{
  addr[0] = x[0];
  addr[1] = x[1];
}
DI void sts(half* addr, const half (&x)[4])
{
  addr[0] = x[0];
  addr[1] = x[1];
  addr[2] = x[2];
  addr[3] = x[3];
}
DI void sts(half* addr, const half (&x)[8])
{
  addr[0] = x[0];
  addr[1] = x[1];
  addr[2] = x[2];
  addr[3] = x[3];
  addr[4] = x[4];
  addr[5] = x[5];
  addr[6] = x[6];
  addr[7] = x[7];
}
DI void sts(float* addr, const float& x) { addr[0] = x; }
DI void sts(float* addr, const float (&x)[1]) { addr[0] = x[0]; }
DI void sts(float* addr, const float (&x)[2])
{
  addr[0] = x[0];
  addr[1] = x[1];
}
DI void sts(float* addr, const float (&x)[4])
{
  addr[0] = x[0];
  addr[1] = x[1];
  addr[2] = x[2];
  addr[3] = x[3];
}
DI void sts(double* addr, const double& x) { addr[0] = x; }
DI void sts(double* addr, const double (&x)[1]) { addr[0] = x[0]; }
DI void sts(double* addr, const double (&x)[2])
{
  addr[0] = x[0];
  addr[1] = x[1];
}
/** @} */

/**
 * @defgroup SmemLoads Shared memory load operations
 * @{
 * @brief Loads from shared memory (LDS)
 *
 * @param[out] x    the data to be loaded
 * @param[in]  addr shared memory address from where to load
 *                  (should be aligned to vector size)
 */
DI void lds(uint8_t& x, const uint8_t* addr) { x = addr[0]; }
DI void lds(uint8_t (&x)[1], const uint8_t* addr) { x[0] = addr[0]; }
DI void lds(uint8_t (&x)[2], const uint8_t* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
}
DI void lds(uint8_t (&x)[4], const uint8_t* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
  x[2] = addr[2];
  x[3] = addr[3];
}
DI void lds(int8_t& x, const int8_t* addr) { x = addr[1]; }
DI void lds(int8_t (&x)[1], const int8_t* addr) { x[0] = addr[0]; }
DI void lds(int8_t (&x)[2], const int8_t* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
}
DI void lds(int8_t (&x)[4], const int8_t* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
  x[2] = addr[2];
  x[3] = addr[3];
}
DI void lds(uint32_t (&x)[4], const uint32_t* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
  x[2] = addr[2];
  x[3] = addr[3];
}
DI void lds(uint32_t (&x)[2], const uint32_t* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
}
DI void lds(uint32_t (&x)[1], const uint32_t* addr) { x[0] = addr[0]; }
DI void lds(uint32_t& x, const uint32_t* addr) { x = addr[0]; }
DI void lds(int32_t (&x)[4], const int32_t* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
  x[2] = addr[2];
  x[3] = addr[3];
}
DI void lds(int32_t (&x)[2], const int32_t* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
}
DI void lds(int32_t (&x)[1], const int32_t* addr) { x[0] = addr[0]; }
DI void lds(int32_t& x, const int32_t* addr) { x = addr[0]; }
DI void lds(half& x, const half* addr) { x = addr[0]; }
DI void lds(half (&x)[1], const half* addr) { x[0] = addr[0]; }
DI void lds(half (&x)[2], const half* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
}
DI void lds(half (&x)[4], const half* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
  x[2] = addr[2];
  x[3] = addr[3];
}
DI void lds(half (&x)[8], const half* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
  x[2] = addr[2];
  x[3] = addr[3];
  x[4] = addr[4];
  x[5] = addr[5];
  x[6] = addr[6];
  x[7] = addr[7];
}
DI void lds(float& x, const float* addr) { x = addr[0]; }
DI void lds(float (&x)[1], const float* addr) { x[0] = addr[0]; }
DI void lds(float (&x)[2], const float* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
}
DI void lds(float (&x)[4], const float* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
  x[2] = addr[2];
  x[3] = addr[3];
}
DI void lds(float& x, float* addr) { x = addr[0]; }
DI void lds(float (&x)[1], float* addr) { x[0] = addr[0]; }
DI void lds(float (&x)[2], float* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
}
DI void lds(float (&x)[4], float* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
  x[2] = addr[2];
  x[3] = addr[3];
}
DI void lds(double& x, double* addr) { x = addr[0]; }
DI void lds(double (&x)[1], double* addr) { x[0] = addr[0]; }
DI void lds(double (&x)[2], double* addr)
{
  x[0] = addr[0];
  x[1] = addr[1];
}
/** @} */

/**
 * @defgroup GlobalLoads Global cached load operations
 * @{
 * @brief Load from global memory with caching(glc)
 * @param[out] x    data to be loaded from global memory
 * @param[in]  addr address in global memory from where to load
 */
DI void ldg(float& x, const float* addr)
{
  x = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<float*>(addr));
}
DI void ldg(float (&x)[1], const float* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<float*>(addr));
}
DI void ldg(float (&x)[2], const float* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<float*>(addr));
  x[1] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<float*>(addr + 1));
}
DI void ldg(float (&x)[4], const float* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<float*>(addr));
  x[1] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<float*>(addr + 1));
  x[2] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<float*>(addr + 2));
  x[3] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<float*>(addr + 3));
}
DI void ldg(half& x, const half* addr)
{
  x = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr));
}
DI void ldg(half (&x)[1], const half* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr));
}
DI void ldg(half (&x)[2], const half* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr));
  x[1] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 1));
}
DI void ldg(half (&x)[4], const half* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr));
  x[1] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 1));
  x[2] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 2));
  x[3] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 3));
}

DI void ldg(half (&x)[8], const half* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr));
  x[1] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 1));
  x[2] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 2));
  x[3] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 3));
  x[4] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 4));
  x[5] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 5));
  x[6] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 6));
  x[7] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<half*>(addr + 7));
}
DI void ldg(double& x, const double* addr)
{
  x = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<double*>(addr));
}
DI void ldg(double (&x)[1], const double* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<double*>(addr));
}
DI void ldg(double (&x)[2], const double* addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<double*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<double*>(addr + 1));
}
DI void ldg(uint32_t& x, const uint32_t* const& addr)
{
  x = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint32_t*>(addr));
}
DI void ldg(uint32_t (&x)[1], const uint32_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint32_t*>(addr));
}
DI void ldg(uint32_t (&x)[2], const uint32_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint32_t*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint32_t*>(addr + 1));
}

DI void ldg(uint32_t (&x)[4], const uint32_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint32_t*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint32_t*>(addr + 1));
  x[2] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint32_t*>(addr + 2));
  x[3] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint32_t*>(addr + 3));
}
DI void ldg(int32_t& x, const int32_t* const& addr)
{
  x = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int32_t*>(addr));
}

DI void ldg(int32_t (&x)[1], const int32_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int32_t*>(addr));
}

DI void ldg(int32_t (&x)[2], const int32_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int32_t*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int32_t*>(addr + 1));
}

DI void ldg(int32_t (&x)[4], const int32_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int32_t*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int32_t*>(addr + 1));
  x[2] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int32_t*>(addr + 2));
  x[3] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int32_t*>(addr + 3));
}

DI void ldg(uint8_t& x, const uint8_t* const& addr)
{
  x = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint8_t*>(addr));
}

DI void ldg(uint8_t (&x)[1], const uint8_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint8_t*>(addr));
}

DI void ldg(uint8_t (&x)[2], const uint8_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint8_t*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint8_t*>(addr + 1));
}

DI void ldg(uint8_t (&x)[4], const uint8_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint8_t*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint8_t*>(addr + 1));
  x[2] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint8_t*>(addr + 2));
  x[3] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<uint8_t*>(addr + 3));
}

DI void ldg(int8_t& x, const int8_t* const& addr)
{
  x = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int8_t*>(addr));
}

DI void ldg(int8_t (&x)[1], const int8_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int8_t*>(addr));
}

DI void ldg(int8_t (&x)[2], const int8_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int8_t*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int8_t*>(addr + 1));
}

DI void ldg(int8_t (&x)[4], const int8_t* const& addr)
{
  x[0] = rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int8_t*>(addr));
  x[1] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int8_t*>(addr + 1));
  x[2] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int8_t*>(addr + 2));
  x[3] =
    rocprim::thread_load<rocprim::cache_load_modifier::load_ldg>(const_cast<int8_t*>(addr + 3));
}

/**
 * @brief Executes a 1D block strided copy
 * @param dst destination pointer
 * @param src source pointer
 * @param size number of items to copy
 */
template <typename T>
DI void block_copy(T* dst, const T* src, const size_t size)
{
  for (auto i = threadIdx.x; i < size; i += blockDim.x) {
    dst[i] = src[i];
  }
}

/**
 * @brief Executes a 1D block strided copy
 * @param dst span of destination pointer
 * @param src span of source pointer
 * @param size number of items to copy
 */
template <typename T>
DI void block_copy(raft::device_span<T> dst,
                   const raft::device_span<const T> src,
                   const size_t size)
{
  assert(src.size() >= size);
  assert(dst.size() >= size);
  block_copy(dst.data(), src.data(), size);
}

/**
 * @brief Executes a 1D block strided copy
 * @param dst span of destination pointer
 * @param src span of source pointer
 * @param size number of items to copy
 */
template <typename T>
DI void block_copy(raft::device_span<T> dst, const raft::device_span<T> src, const size_t size)
{
  assert(src.size() >= size);
  assert(dst.size() >= size);
  block_copy(dst.data(), src.data(), size);
}

/**
 * @brief Executes a 1D block strided copy
 * @param dst span of destination pointer
 * @param src span of source pointer
 */
template <typename T>
DI void block_copy(raft::device_span<T> dst, const raft::device_span<T> src)
{
  assert(dst.size() >= src.size());
  block_copy(dst, src, src.size());
}

/** @} */

/** @} */

/**
 * @defgroup GlobalStores Global Store Operations
 * @{
 * @brief Perform conditional stores to global memory.
 *
 * These functions store data to a specified global memory address,
 * controlled by a guard flag to enable conditional execution.
 *
 * @param[in] reg   The data to store in global memory.
 *                  The type of `reg` determines the size of the store.
 * @param[in] addr  The global memory address where the data will be stored.
 * @param[in] guard A flag to conditionally enable the store operation.
 *                  If `true`, the store is performed; otherwise, it is skipped
 */

DI void stg(const int& reg, void* addr, bool guard)
{
  if (guard) {
    auto offset = static_cast<uint64_t>(reinterpret_cast<uintptr_t>(addr));
    asm volatile("global_store_dword %0, %1 off glc \n \t" : : "v"(offset), "v"(reg));
  }
}

DI void stg(const int64_t& reg, void* addr, bool guard)
{
  if (guard) {
    auto offset = static_cast<uint64_t>(reinterpret_cast<uintptr_t>(addr));

    asm volatile("global_store_dwordx2 %0, %1 off glc \n \t" : : "v"(offset), "v"(reg));
  }
}

/** @} */

}  // namespace raft

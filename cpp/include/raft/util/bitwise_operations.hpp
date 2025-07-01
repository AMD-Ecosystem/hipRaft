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

#include <cstdint>
#include <type_traits>
#ifdef __HIP_PLATFORM_AMD__
#include <raft/cuda_runtime.h>
#else
#include <cuda_runtime_api.h>
#endif

namespace raft {
/**
 * \brief Computes the population count (number of bits set to 1) in the provided integer.
 */
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 8, unsigned int> __POPC(T v)
{
  static_assert(std::is_integral_v<T>);
  return __popcll(static_cast<unsigned long long>(v));
}
/**
 * \brief Computes the population count (number of bits set to 1) in the provided integer.
 */
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 4, unsigned int> __POPC(T v)
{
  static_assert(std::is_integral_v<T>);
  return __popc(static_cast<unsigned int>(v));
}

/**
 * \brief Find First Set. Return index of first set bit of lowest significance.
 **/
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 8, int> __FFS(T v)
{
  static_assert(std::is_integral_v<T>);
  return __ffsll(static_cast<unsigned long long int>(v));
}

/**
 * \brief Find First Set. Return index of first set bit of lowest significance.
 **/
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 4, int> __FFS(T v)
{
  static_assert(std::is_integral_v<T>);
  return __ffs(static_cast<int>(v));
}

/**
 \brief Bit-reversal helper that wraps __brevll intrinsic
**/
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 8, unsigned long long> __BREV(T v)
{
  static_assert(std::is_integral_v<T>);
  return __brevll(static_cast<unsigned long long int>(v));
}

/**
 \brief Bit-reversal helper that wraps __brev intrinsic
**/
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 4, unsigned int> __BREV(T v)
{
  static_assert(std::is_integral_v<T>);
  return __brev(static_cast<unsigned int>(v));
}

/**
 \brief Helper that wraps __clzll intrinsic to count the number of leading zeros.
**/
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 8, int> __CLZ(T v)
{
  static_assert(std::is_integral_v<T>);
  return __clzll(static_cast<long long int>(v));
}

/**
 \brief Helper that wraps __clz intrinsic to count the number of leading zeros.
**/
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 4, int> __CLZ(T v)
{
  static_assert(std::is_integral_v<T>);
  return __clz(static_cast<int>(v));
}

/**
 \brief Helper that wraps __fns64 intrinsics to find the position of the n-th  bit set to 1 in a
64-bit integer
**/
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 8, int32_t> __FNS(T mask, uint32_t base, int32_t offset)
{
  static_assert(std::is_integral_v<T>);
  return __fns64(static_cast<uint64_t>(mask), base, offset);
}

/**
 \brief Helper that wraps __fns32 intrinsics to find the position of the n-th bit set to 1 in a
32-bit integer
**/
template <typename T>
__device__ std::enable_if_t<sizeof(T) == 4, int32_t> __FNS(T mask, uint32_t base, int32_t offset)
{
  static_assert(std::is_integral_v<T>);
  return __fns32(static_cast<uint32_t>(mask), base, offset);
}

}  // namespace raft

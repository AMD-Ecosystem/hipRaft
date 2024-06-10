/*
 * Copyright (c) 2022-2024, NVIDIA CORPORATION.
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
 * Modifications Copyright (c) 2024 Advanced Micro Devices, Inc.
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
#include <raft/core/memory_type.hpp>

#ifdef __HIP_PLATFORM_AMD__
#include <raft/cuda_runtime.h>
#else
#include <cuda_runtime.h>
#endif

#include <gtest/gtest.h>

namespace raft {
TEST(MemoryType, IsDeviceAccessible)
{
  static_assert(!is_device_accessible(memory_type::host));
  static_assert(is_device_accessible(memory_type::device));
  static_assert(is_device_accessible(memory_type::managed));
  static_assert(is_device_accessible(memory_type::pinned));
}

TEST(MemoryType, IsHostAccessible)
{
  static_assert(is_host_accessible(memory_type::host));
  static_assert(!is_host_accessible(memory_type::device));
  static_assert(is_host_accessible(memory_type::managed));
  static_assert(is_host_accessible(memory_type::pinned));
}

TEST(MemoryType, IsHostDeviceAccessible)
{
  static_assert(!is_host_device_accessible(memory_type::host));
  static_assert(!is_host_device_accessible(memory_type::device));
  static_assert(is_host_device_accessible(memory_type::managed));
  static_assert(is_host_device_accessible(memory_type::pinned));
}

TEST(MemoryTypeFromPointer, Host)
{
  auto ptr1 = static_cast<void*>(nullptr);
  cudaMallocHost(&ptr1, 1);
  EXPECT_EQ(memory_type_from_pointer(ptr1), memory_type::host);
  cudaFreeHost(ptr1);
  auto ptr2 = static_cast<void*>(nullptr);
  EXPECT_EQ(memory_type_from_pointer(ptr2), memory_type::host);
}

#ifndef RAFT_DISABLE_CUDA
TEST(MemoryTypeFromPointer, Device)
{
  auto ptr = static_cast<void*>(nullptr);
  cudaMalloc(&ptr, 1);
  EXPECT_EQ(memory_type_from_pointer(ptr), memory_type::device);
  cudaFree(ptr);
}
TEST(MemoryTypeFromPointer, Managed)
{
  auto ptr = static_cast<void*>(nullptr);
  cudaMallocManaged(&ptr, 1);
  EXPECT_EQ(memory_type_from_pointer(ptr), memory_type::managed);
  cudaFree(ptr);
}
#endif
}  // namespace raft

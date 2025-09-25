// MIT License
//
// Copyright (c) 2024-2025 Advanced Micro Devices, Inc.
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

#include <hipblaslt/hipblaslt.h>

#include <mutex>

// types
#ifndef cublasLtHandle_t
#define cublasLtHandle_t hipblasLtHandle_t
#endif
#ifndef cublasLtMatrixLayout_t
#define cublasLtMatrixLayout_t hipblasLtMatrixLayout_t
#endif
#ifndef cublasLtMatmulDesc_t
#define cublasLtMatmulDesc_t hipblasLtMatmulDesc_t
#endif
#ifndef cublasLtMatmulHeuristicResult_t
#define cublasLtMatmulHeuristicResult_t hipblasLtMatmulHeuristicResult_t
#endif
#ifndef cublasLtMatmulPreference_t
#define cublasLtMatmulPreference_t hipblasLtMatmulPreference_t
#endif

#ifndef cudaDataType
#define cudaDataType hipDataType
#endif

// macros
#ifndef CUBLASLT_MATMUL_DESC_POINTER_MODE
#define CUBLASLT_MATMUL_DESC_POINTER_MODE HIPBLASLT_MATMUL_DESC_POINTER_MODE
#endif
#ifndef CUBLASLT_MATMUL_DESC_TRANSA
#define CUBLASLT_MATMUL_DESC_TRANSA HIPBLASLT_MATMUL_DESC_TRANSA
#endif
#ifndef CUBLASLT_MATMUL_DESC_TRANSB
#define CUBLASLT_MATMUL_DESC_TRANSB HIPBLASLT_MATMUL_DESC_TRANSB
#endif

namespace raft {
namespace detail {
struct InternalHipblasLtHandle {
  hipblasLtHandle_t handle;
  std::mutex mutex;
};
}  // namespace detail
}  // namespace raft

// functions
#ifdef cublasLtCreate
#undef cublasLtCreate
#endif
inline hipblasStatus_t cublasLtCreate(hipblasLtHandle_t* handle)
{
  static_assert(sizeof(hipblasLtHandle_t) == sizeof(raft::detail::InternalHipblasLtHandle*),
                "Size mismatch");
  auto* outer_handle = new raft::detail::InternalHipblasLtHandle;
  auto status        = hipblasLtCreate(&outer_handle->handle);
  *handle            = reinterpret_cast<hipblasLtHandle_t>(outer_handle);
  return status;
}

#ifdef cublasLtDestroy
#undef cublasLtDestroy
#endif
inline hipblasStatus_t cublasLtDestroy(hipblasLtHandle_t handle)
{
  static_assert(sizeof(hipblasLtHandle_t) == sizeof(raft::detail::InternalHipblasLtHandle*),
                "Size mismatch");
  auto* outer_handle = reinterpret_cast<raft::detail::InternalHipblasLtHandle*>(handle);
  auto status        = hipblasLtDestroy(outer_handle->handle);
  delete outer_handle;
  return status;
}

#ifndef cublasLtMatrixLayoutCreate
#define cublasLtMatrixLayoutCreate hipblasLtMatrixLayoutCreate
#endif
#ifndef cublasLtMatrixLayoutDestroy
#define cublasLtMatrixLayoutDestroy hipblasLtMatrixLayoutDestroy
#endif

#ifndef cublasLtMatmulDescCreate
#define cublasLtMatmulDescCreate hipblasLtMatmulDescCreate
#endif
#ifndef cublasLtMatmulDescDestroy
#define cublasLtMatmulDescDestroy hipblasLtMatmulDescDestroy
#endif
#ifndef cublasLtMatmulPreferenceCreate
#define cublasLtMatmulPreferenceCreate hipblasLtMatmulPreferenceCreate
#endif

#ifdef cublasLtMatmulAlgoGetHeuristic
#undef cublasLtMatmulAlgoGetHeuristic
#endif

inline hipblasStatus_t cublasLtMatmulAlgoGetHeuristic(
  hipblasLtHandle_t handle,
  hipblasLtMatmulDesc_t matmulDesc,
  hipblasLtMatrixLayout_t Adesc,
  hipblasLtMatrixLayout_t Bdesc,
  hipblasLtMatrixLayout_t Cdesc,
  hipblasLtMatrixLayout_t Ddesc,
  hipblasLtMatmulPreference_t pref,
  int requestedAlgoCount,
  hipblasLtMatmulHeuristicResult_t heuristicResultsArray[],
  int* returnAlgoCount)
{
  auto outer_handle = reinterpret_cast<raft::detail::InternalHipblasLtHandle*>(handle);
  std::unique_lock<std::mutex> lock(outer_handle->mutex);
  return hipblasLtMatmulAlgoGetHeuristic(outer_handle->handle,
                                         matmulDesc,
                                         Adesc,
                                         Bdesc,
                                         Cdesc,
                                         Ddesc,
                                         pref,
                                         requestedAlgoCount,
                                         heuristicResultsArray,
                                         returnAlgoCount);
}

#ifndef cublasLtMatmulPreferenceDestroy
#define cublasLtMatmulPreferenceDestroy hipblasLtMatmulPreferenceDestroy
#endif
#ifndef cublasLtMatmulDescSetAttribute
#define cublasLtMatmulDescSetAttribute hipblasLtMatmulDescSetAttribute
#endif

#ifdef cublasLtMatmul
#undef cublasLtMatmul
#endif

inline hipblasStatus_t cublasLtMatmul(hipblasLtHandle_t handle,
                                      hipblasLtMatmulDesc_t matmulDesc,
                                      const void* alpha,
                                      const void* A,
                                      hipblasLtMatrixLayout_t Adesc,
                                      const void* B,
                                      hipblasLtMatrixLayout_t Bdesc,
                                      const void* beta,
                                      const void* C,
                                      hipblasLtMatrixLayout_t Cdesc,
                                      void* D,
                                      hipblasLtMatrixLayout_t Ddesc,
                                      const hipblasLtMatmulAlgo_t* algo,
                                      void* workspace,
                                      size_t workspaceSizeInBytes,
                                      hipStream_t stream)
{
  auto outer_handle = reinterpret_cast<raft::detail::InternalHipblasLtHandle*>(handle);
  std::unique_lock<std::mutex> lock(outer_handle->mutex);
  return hipblasLtMatmul(outer_handle->handle,
                         matmulDesc,
                         alpha,
                         A,
                         Adesc,
                         B,
                         Bdesc,
                         beta,
                         C,
                         Cdesc,
                         D,
                         Ddesc,
                         algo,
                         workspace,
                         workspaceSizeInBytes,
                         stream);
}

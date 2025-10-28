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

#define HIPBLAS_V2
#include <hipblas/hipblas.h>

// Types
#ifndef cublasComputeType_t
#define cublasComputeType_t hipblasComputeType_t
#endif
#ifndef cublasDiagType_t
#define cublasDiagType_t hipblasDiagType_t
#endif
#ifndef cublasFillMode_t
#define cublasFillMode_t hipblasFillMode_t
#endif
#ifndef cublasHandle_t
#define cublasHandle_t hipblasHandle_t
#endif
#ifndef cublasOperation_t
#define cublasOperation_t hipblasOperation_t
#endif
#ifndef cublasPointerMode_t
#define cublasPointerMode_t hipblasPointerMode_t
#endif
#ifndef cublasSideMode_t
#define cublasSideMode_t hipblasSideMode_t
#endif
#ifndef cublasStatus_t
#define cublasStatus_t hipblasStatus_t
#endif

// Macros, constants, enums
#ifndef CUBLAS_COMPUTE_16F
#define CUBLAS_COMPUTE_16F HIPBLAS_COMPUTE_16F
#endif
#ifndef CUBLAS_COMPUTE_32F
#define CUBLAS_COMPUTE_32F HIPBLAS_COMPUTE_32F
#endif
#ifndef CUBLAS_COMPUTE_32I
#define CUBLAS_COMPUTE_32I HIPBLAS_COMPUTE_32I
#endif
#ifndef CUBLAS_COMPUTE_64F
#define CUBLAS_COMPUTE_64F HIPBLAS_COMPUTE_64F
#endif
#ifndef CUBLAS_DIAG_NON_UNIT
#define CUBLAS_DIAG_NON_UNIT HIPBLAS_DIAG_NON_UNIT
#endif
#ifndef CUBLAS_FILL_MODE_LOWER
#define CUBLAS_FILL_MODE_LOWER HIPBLAS_FILL_MODE_LOWER
#endif
#ifndef CUBLAS_FILL_MODE_UPPER
#define CUBLAS_FILL_MODE_UPPER HIPBLAS_FILL_MODE_UPPER
#endif
#ifndef CUBLAS_OP_N
#define CUBLAS_OP_N HIPBLAS_OP_N
#endif
#ifndef CUBLAS_OP_T
#define CUBLAS_OP_T HIPBLAS_OP_T
#endif
#ifndef CUBLAS_POINTER_MODE_DEVICE
#define CUBLAS_POINTER_MODE_DEVICE HIPBLAS_POINTER_MODE_DEVICE
#endif
#ifndef CUBLAS_POINTER_MODE_HOST
#define CUBLAS_POINTER_MODE_HOST HIPBLAS_POINTER_MODE_HOST
#endif
#ifndef CUBLAS_STATUS_ALLOC_FAILED
#define CUBLAS_STATUS_ALLOC_FAILED HIPBLAS_STATUS_ALLOC_FAILED
#endif
#ifndef CUBLAS_STATUS_ARCH_MISMATCH
#define CUBLAS_STATUS_ARCH_MISMATCH HIPBLAS_STATUS_ARCH_MISMATCH
#endif
#ifndef CUBLAS_STATUS_EXECUTION_FAILED
#define CUBLAS_STATUS_EXECUTION_FAILED HIPBLAS_STATUS_EXECUTION_FAILED
#endif
#ifndef CUBLAS_STATUS_INTERNAL_ERROR
#define CUBLAS_STATUS_INTERNAL_ERROR HIPBLAS_STATUS_INTERNAL_ERROR
#endif
#ifndef CUBLAS_STATUS_INVALID_VALUE
#define CUBLAS_STATUS_INVALID_VALUE HIPBLAS_STATUS_INVALID_VALUE
#endif
// TODO(FIXME/HIP): HIPBLAS_STATUS_LICENSE_ERROR is not supported (?)
#ifndef CUBLAS_STATUS_LICENSE_ERROR
#define CUBLAS_STATUS_LICENSE_ERROR HIPBLAS_STATUS_LICENSE_ERROR
#endif
#ifndef CUBLAS_STATUS_MAPPING_ERROR
#define CUBLAS_STATUS_MAPPING_ERROR HIPBLAS_STATUS_MAPPING_ERROR
#endif
#ifndef CUBLAS_STATUS_NOT_INITIALIZED
#define CUBLAS_STATUS_NOT_INITIALIZED HIPBLAS_STATUS_NOT_INITIALIZED
#endif
#ifndef CUBLAS_STATUS_NOT_SUPPORTED
#define CUBLAS_STATUS_NOT_SUPPORTED HIPBLAS_STATUS_NOT_SUPPORTED
#endif
#ifndef CUBLAS_STATUS_SUCCESS
#define CUBLAS_STATUS_SUCCESS HIPBLAS_STATUS_SUCCESS
#endif
#ifndef CUBLAS_SIDE_LEFT
#define CUBLAS_SIDE_LEFT HIPBLAS_SIDE_LEFT
#endif
#ifndef CUDA_R_16F
#define CUDA_R_16F HIP_R_16F
#endif
#ifndef CUDA_C_16F
#define CUDA_C_16F HIP_C_16F
#endif
#ifndef CUDA_R_16BF
#define CUDA_R_16BF HIP_R_16BF
#endif
#ifndef CUDA_C_16BF
#define CUDA_C_16BF HIP_C_16BF
#endif
#ifndef CUDA_R_32F
#define CUDA_R_32F HIP_R_32F
#endif
#ifndef CUDA_C_32F
#define CUDA_C_32F HIP_C_32F
#endif
#ifndef CUDA_R_64F
#define CUDA_R_64F HIP_R_64F
#endif
#ifndef CUDA_C_64F
#define CUDA_C_64F HIP_C_64F
#endif
#ifndef CUDA_R_4I
#define CUDA_R_4I HIP_R_4I
#endif
#ifndef CUDA_C_4I
#define CUDA_C_4I HIP_C_4I
#endif
#ifndef CUDA_R_4U
#define CUDA_R_4U HIP_R_4U
#endif
#ifndef CUDA_C_4U
#define CUDA_C_4U HIP_C_4U
#endif
#ifndef CUDA_R_8I
#define CUDA_R_8I HIP_R_8I
#endif
#ifndef CUDA_C_8I
#define CUDA_C_8I HIP_C_8I
#endif
#ifndef CUDA_R_8U
#define CUDA_R_8U HIP_R_8U
#endif
#ifndef CUDA_C_8U
#define CUDA_C_8U HIP_C_8U
#endif
#ifndef CUDA_R_16I
#define CUDA_R_16I HIP_R_16I
#endif
#ifndef CUDA_C_16I
#define CUDA_C_16I HIP_C_16I
#endif
#ifndef CUDA_R_16U
#define CUDA_R_16U HIP_R_16U
#endif
#ifndef CUDA_C_16U
#define CUDA_C_16U HIP_C_16U
#endif
#ifndef CUDA_R_32I
#define CUDA_R_32I HIP_R_32I
#endif
#ifndef CUDA_C_32I
#define CUDA_C_32I HIP_C_32I
#endif
#ifndef CUDA_R_32U
#define CUDA_R_32U HIP_R_32U
#endif
#ifndef CUDA_C_32U
#define CUDA_C_32U HIP_C_32U
#endif
#ifndef CUDA_R_64I
#define CUDA_R_64I HIP_R_64I
#endif
#ifndef CUDA_C_64I
#define CUDA_C_64I HIP_C_64I
#endif
#ifndef CUDA_R_64U
#define CUDA_R_64U HIP_R_64U
#endif
#ifndef CUDA_C_64U
#define CUDA_C_64U HIP_C_64U
#endif

// Functions
#ifndef cublasCreate
#define cublasCreate hipblasCreate
#endif
#ifndef cublasDaxpy
#define cublasDaxpy hipblasDaxpy
#endif
#ifndef cublasDcopy
#define cublasDcopy hipblasDcopy
#endif
#ifndef cublasDestroy
#define cublasDestroy hipblasDestroy
#endif
#ifndef cublasDgeam
#define cublasDgeam hipblasDgeam
#endif
#ifndef cublasDgelsBatched
#define cublasDgelsBatched hipblasDgelsBatched
#endif
#ifndef cublasDgemm
#define cublasDgemm hipblasDgemm
#endif
#ifndef cublasDgemmBatched
#define cublasDgemmBatched hipblasDgemmBatched
#endif
#ifndef cublasDgemmStridedBatched
#define cublasDgemmStridedBatched hipblasDgemmStridedBatched
#endif
#ifndef cublasDgemv
#define cublasDgemv hipblasDgemv
#endif
#ifndef cublasDger
#define cublasDger hipblasDger
#endif
#ifndef cublasDgetrfBatched
#define cublasDgetrfBatched hipblasDgetrfBatched
#endif
#ifndef cublasDgetriBatched
#define cublasDgetriBatched hipblasDgetriBatched
#endif
#ifndef cublasDnrm2
#define cublasDnrm2 hipblasDnrm2
#endif
#ifndef cublasDotEx
#define cublasDotEx hipblasDotEx
#endif
#ifndef cublasDscal
#define cublasDscal hipblasDscal
#endif
#ifndef cublasDswap
#define cublasDswap hipblasDswap
#endif
#ifndef cublasDsymm
#define cublasDsymm hipblasDsymm
#endif
#ifndef cublasDsyrk
#define cublasDsyrk hipblasDsyrk
#endif
#ifndef cublasDtrsm
#define cublasDtrsm hipblasDtrsm
#endif
#ifndef cublasSaxpy
#define cublasSaxpy hipblasSaxpy
#endif
#ifndef cublasScopy
#define cublasScopy hipblasScopy
#endif
#ifndef cublasSetPointerMode
#define cublasSetPointerMode hipblasSetPointerMode
#endif
#ifndef cublasSetStream
#define cublasSetStream hipblasSetStream
#endif
#ifndef cublasSgeam
#define cublasSgeam hipblasSgeam
#endif
#ifndef cublasSgelsBatched
#define cublasSgelsBatched hipblasSgelsBatched
#endif
#ifndef cublasSgemm
#define cublasSgemm hipblasSgemm
#endif
#ifndef cublasSgemmBatched
#define cublasSgemmBatched hipblasSgemmBatched
#endif
#ifndef cublasSgemmStridedBatched
#define cublasSgemmStridedBatched hipblasSgemmStridedBatched
#endif
#ifndef cublasSgemv
#define cublasSgemv hipblasSgemv
#endif
#ifndef cublasSger
#define cublasSger hipblasSger
#endif
#ifndef cublasSgetrfBatched
#define cublasSgetrfBatched hipblasSgetrfBatched
#endif
#ifndef cublasSgetriBatched
#define cublasSgetriBatched hipblasSgetriBatched
#endif
#ifndef cublasSnrm2
#define cublasSnrm2 hipblasSnrm2
#endif
#ifndef cublasSscal
#define cublasSscal hipblasSscal
#endif
#ifndef cublasSswap
#define cublasSswap hipblasSswap
#endif
#ifndef cublasSsymm
#define cublasSsymm hipblasSsymm
#endif
#ifndef cublasSsyrk
#define cublasSsyrk hipblasSsyrk
#endif
#ifndef cublasStrsm
#define cublasStrsm hipblasStrsm
#endif

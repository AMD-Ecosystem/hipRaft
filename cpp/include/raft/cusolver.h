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

#include <hipsolver/hipsolver.h>

#define CUSOLVERAPI

// types
#ifndef csrqrInfo
#define csrqrInfo hipsolvercsrqrInfo
#endif
#ifndef csrqrInfo_t
#define csrqrInfo_t hipsolvercsrqrInfo_t
#endif
#ifndef cusolverDnHandle_t
#define cusolverDnHandle_t hipsolverDnHandle_t
#endif
#ifndef cusolverDnParams_t
#define cusolverDnParams_t hipsolverDnParams_t
#endif
#ifndef cusolverEigMode_t
#define cusolverEigMode_t hipsolverEigMode_t
#endif
#ifndef cusolverEigRange_t
#define cusolverEigRange_t hipsolverEigRange_t
#endif
#ifndef cusolverSpHandle_t
#define cusolverSpHandle_t hipsolverSpHandle_t
#endif
#ifndef cusolverStatus_t
#define cusolverStatus_t hipsolverStatus_t
#endif
#ifndef cusparseMatDescr_t
#define cusparseMatDescr_t hipsparseMatDescr_t
#endif
#ifndef gesvdjInfo_t
#define gesvdjInfo_t hipsolverGesvdjInfo_t
#endif
#ifndef syevjInfo
#define syevjInfo hipsyevjInfo
#endif
#ifndef syevjInfo_t
#define syevjInfo_t hipsolverSyevjInfo_t
#endif

// macros/constants
#ifndef CUSOLVER_EIG_MODE_VECTOR
#define CUSOLVER_EIG_MODE_VECTOR HIPSOLVER_EIG_MODE_VECTOR
#endif
#ifndef CUSOLVER_EIG_RANGE_I
#define CUSOLVER_EIG_RANGE_I HIPSOLVER_EIG_RANGE_I
#endif
#ifndef CUSOLVER_STATUS_ALLOC_FAILED
#define CUSOLVER_STATUS_ALLOC_FAILED HIPSOLVER_STATUS_ALLOC_FAILED
#endif
#ifndef CUSOLVER_STATUS_ARCH_MISMATCH
#define CUSOLVER_STATUS_ARCH_MISMATCH HIPSOLVER_STATUS_ARCH_MISMATCH
#endif
#ifndef CUSOLVER_STATUS_EXECUTION_FAILED
#define CUSOLVER_STATUS_EXECUTION_FAILED HIPSOLVER_STATUS_EXECUTION_FAILED
#endif
#ifndef CUSOLVER_STATUS_INTERNAL_ERROR
#define CUSOLVER_STATUS_INTERNAL_ERROR HIPSOLVER_STATUS_INTERNAL_ERROR
#endif
#ifndef CUSOLVER_STATUS_INVALID_VALUE
#define CUSOLVER_STATUS_INVALID_VALUE HIPSOLVER_STATUS_INVALID_VALUE
#endif
#ifndef CUSOLVER_STATUS_MATRIX_TYPE_NOT_SUPPORTED
#define CUSOLVER_STATUS_MATRIX_TYPE_NOT_SUPPORTED HIPSOLVER_STATUS_MATRIX_TYPE_NOT_SUPPORTED
#endif
#ifndef CUSOLVER_STATUS_NOT_INITIALIZED
#define CUSOLVER_STATUS_NOT_INITIALIZED HIPSOLVER_STATUS_NOT_INITIALIZED
#endif
#ifndef CUSOLVER_STATUS_NOT_SUPPORTED
#define CUSOLVER_STATUS_NOT_SUPPORTED HIPSOLVER_STATUS_NOT_SUPPORTED
#endif
#ifndef CUSOLVER_STATUS_SUCCESS
#define CUSOLVER_STATUS_SUCCESS HIPSOLVER_STATUS_SUCCESS
#endif
#ifndef CUSOLVER_STATUS_ZERO_PIVOT
#define CUSOLVER_STATUS_ZERO_PIVOT HIPSOLVER_STATUS_ZERO_PIVOT
#endif

// functions
#ifndef cusolverDnCreate
#define cusolverDnCreate hipsolverDnCreate
#endif
#ifndef cusolverDnCreateGesvdjInfo
#define cusolverDnCreateGesvdjInfo hipsolverDnCreateGesvdjInfo
#endif
#ifndef cusolverDnCreateParams
#define cusolverDnCreateParams hipsolverDnCreateParams
#endif
#ifndef cusolverDnCreateSyevjInfo
#define cusolverDnCreateSyevjInfo hipsolverDnCreateSyevjInfo
#endif
#ifndef cusolverDnDestroy
#define cusolverDnDestroy hipsolverDnDestroy
#endif
#ifndef cusolverDnDestroyGesvdjInfo
#define cusolverDnDestroyGesvdjInfo hipsolverDnDestroyGesvdjInfo
#endif
#ifndef cusolverDnDestroyParams
#define cusolverDnDestroyParams hipsolverDnDestroyParams
#endif
#ifndef cusolverDnDestroySyevjInfo
#define cusolverDnDestroySyevjInfo hipsolverDnDestroySyevjInfo
#endif
#ifndef cusolverDnDgeqrf
#define cusolverDnDgeqrf hipsolverDnDgeqrf
#endif
#ifndef cusolverDnDgeqrf_bufferSize
#define cusolverDnDgeqrf_bufferSize hipsolverDnDgeqrf_bufferSize
#endif
#ifndef cusolverDnDgesvd
#define cusolverDnDgesvd hipsolverDnDgesvd
#endif
#ifndef cusolverDnDgesvd_bufferSize
#define cusolverDnDgesvd_bufferSize hipsolverDnDgesvd_bufferSize
#endif
#ifndef cusolverDnDgesvdj
#define cusolverDnDgesvdj hipsolverDnDgesvdj
#endif
#ifndef cusolverDnDgesvdj_bufferSize
#define cusolverDnDgesvdj_bufferSize hipsolverDnDgesvdj_bufferSize
#endif
#ifndef cuSolverDnDgesvdj_bufferSize
#define cuSolverDnDgesvdj_bufferSize hipsolverDnDgesvdj_bufferSize
#endif
#ifndef cusolverDnDgetrf
#define cusolverDnDgetrf hipsolverDnDgetrf
#endif
#ifndef cusolverDnDgetrf_bufferSize
#define cusolverDnDgetrf_bufferSize hipsolverDnDgetrf_bufferSize
#endif
#ifndef cusolverDnDgetrs
#define cusolverDnDgetrs hipsolverDnDgetrs
#endif
#ifndef cusolverDnDorgqr
#define cusolverDnDorgqr hipsolverDnDorgqr
#endif
#ifndef cuSolverDnDorgqr
#define cuSolverDnDorgqr hipsolverDnDorgqr
#endif
#ifndef cusolverDnDorgqr_bufferSize
#define cusolverDnDorgqr_bufferSize hipsolverDnDorgqr_bufferSize
#endif
#ifndef cusolverDnDormqr
#define cusolverDnDormqr hipsolverDnDormqr
#endif
#ifndef cusolverDnDormqr_bufferSize
#define cusolverDnDormqr_bufferSize hipsolverDnDormqr_bufferSize
#endif
#ifndef cusolverDnDpotrf
#define cusolverDnDpotrf hipsolverDnDpotrf
#endif
#ifndef cuSolverDnDpotrf
#define cuSolverDnDpotrf hipsolverDnDpotrf
#endif
#ifndef cusolverDnDpotrf_bufferSize
#define cusolverDnDpotrf_bufferSize hipsolverDnDpotrf_bufferSize
#endif
#ifndef cusolverDnDpotrs
#define cusolverDnDpotrs hipsolverDnDpotrs
#endif
#ifndef cuSolverDnDpotrs
#define cuSolverDnDpotrs hipsolverDnDpotrs
#endif
#ifndef cusolverDnDsyevd
#define cusolverDnDsyevd hipsolverDnDsyevd
#endif
#ifndef cusolverDnDsyevd_bufferSize
#define cusolverDnDsyevd_bufferSize hipsolverDnDsyevd_bufferSize
#endif
#ifndef cusolverDnDsyevdx
#define cusolverDnDsyevdx hipsolverDnDsyevdx
#endif
#ifndef cusolverDnDsyevdx_bufferSize
#define cusolverDnDsyevdx_bufferSize hipsolverDnDsyevdx_bufferSize
#endif
#ifndef cusolverDnDsyevj
#define cusolverDnDsyevj hipsolverDnDsyevj
#endif
#ifndef cusolverDnDsyevj_bufferSize
#define cusolverDnDsyevj_bufferSize hipsolverDnDsyevj_bufferSize
#endif
#ifndef cusolverDngesvd_bufferSize
#define cusolverDngesvd_bufferSize hipsolverDngesvd_bufferSize
#endif
#ifndef cusolverDngesvdj_bufferSize
#define cusolverDngesvdj_bufferSize hipsolverDngesvdj_bufferSize
#endif
#ifndef cusolverDnSetStream
#define cusolverDnSetStream hipsolverDnSetStream
#endif
#ifndef cusolverDnSgeqrf
#define cusolverDnSgeqrf hipsolverDnSgeqrf
#endif
#ifndef cusolverDnSgeqrf_bufferSize
#define cusolverDnSgeqrf_bufferSize hipsolverDnSgeqrf_bufferSize
#endif
#ifndef cusolverDnSgesvd
#define cusolverDnSgesvd hipsolverDnSgesvd
#endif
#ifndef cusolverDnSgesvd_bufferSize
#define cusolverDnSgesvd_bufferSize hipsolverDnSgesvd_bufferSize
#endif
#ifndef cusolverDnSgesvdj
#define cusolverDnSgesvdj hipsolverDnSgesvdj
#endif
#ifndef cuSolverDnSgesvdj
#define cuSolverDnSgesvdj hipsolverDnSgesvdj
#endif
#ifndef cusolverDnSgesvdj_bufferSize
#define cusolverDnSgesvdj_bufferSize hipsolverDnSgesvdj_bufferSize
#endif
#ifndef cusolverDnSgetrf
#define cusolverDnSgetrf hipsolverDnSgetrf
#endif
#ifndef cusolverDnSgetrf_bufferSize
#define cusolverDnSgetrf_bufferSize hipsolverDnSgetrf_bufferSize
#endif
#ifndef cusolverDnSgetrs
#define cusolverDnSgetrs hipsolverDnSgetrs
#endif
#ifndef cusolverDnSorgqr
#define cusolverDnSorgqr hipsolverDnSorgqr
#endif
#ifndef cuSolverDnSorgqr
#define cuSolverDnSorgqr hipsolverDnSorgqr
#endif
#ifndef cusolverDnSorgqr_bufferSize
#define cusolverDnSorgqr_bufferSize hipsolverDnSorgqr_bufferSize
#endif
#ifndef cusolverDnSormqr
#define cusolverDnSormqr hipsolverDnSormqr
#endif
#ifndef cusolverDnSormqr_bufferSize
#define cusolverDnSormqr_bufferSize hipsolverDnSormqr_bufferSize
#endif
#ifndef cusolverDnSpotrf
#define cusolverDnSpotrf hipsolverDnSpotrf
#endif
#ifndef cusolverDnSpotrf_bufferSize
#define cusolverDnSpotrf_bufferSize hipsolverDnSpotrf_bufferSize
#endif
#ifndef cusolverDnSpotrs
#define cusolverDnSpotrs hipsolverDnSpotrs
#endif
#ifndef cusolverDnSsyevd
#define cusolverDnSsyevd hipsolverDnSsyevd
#endif
#ifndef cusolverDnSsyevd_bufferSize
#define cusolverDnSsyevd_bufferSize hipsolverDnSsyevd_bufferSize
#endif
#ifndef cusolverDnSsyevdx
#define cusolverDnSsyevdx hipsolverDnSsyevdx
#endif
#ifndef cusolverDnSsyevdx_bufferSize
#define cusolverDnSsyevdx_bufferSize hipsolverDnSsyevdx_bufferSize
#endif
#ifndef cusolverDnSsyevj
#define cusolverDnSsyevj hipsolverDnSsyevj
#endif
#ifndef cusolverDnSsyevj_bufferSize
#define cusolverDnSsyevj_bufferSize hipsolverDnSsyevj_bufferSize
#endif
#ifndef cusolverDnsyevd_bufferSize
#define cusolverDnsyevd_bufferSize hipsolverDnsyevd_bufferSize
#endif
#ifndef cusolverDnXgesvd
#define cusolverDnXgesvd hipsolverDnXgesvd
#endif
#ifndef cusolverDnXgesvdjSetMaxSweeps
#define cusolverDnXgesvdjSetMaxSweeps hipsolverDnXgesvdjSetMaxSweeps
#endif
#ifndef cusolverDnXgesvdjSetTolerance
#define cusolverDnXgesvdjSetTolerance hipsolverDnXgesvdjSetTolerance
#endif
#ifndef cusolverDnXsyevjGetSweeps
#define cusolverDnXsyevjGetSweeps hipsolverDnXsyevjGetSweeps
#endif
#ifndef cusolverDnXsyevjSetMaxSweeps
#define cusolverDnXsyevjSetMaxSweeps hipsolverDnXsyevjSetMaxSweeps
#endif
#ifndef cusolverDnXsyevjSetTolerance
#define cusolverDnXsyevjSetTolerance hipsolverDnXsyevjSetTolerance
#endif
#ifndef cusolverSpCreate
#define cusolverSpCreate hipsolverSpCreate
#endif
#ifndef cusolverSpDestroy
#define cusolverSpDestroy hipsolverSpDestroy
#endif
#ifndef cusolverSpSetStream
#define cusolverSpSetStream hipsolverSpSetStream
#endif

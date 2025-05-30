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

#include <hiprand/hiprand.h>

// types
#ifndef curandGenerator_t
#define curandGenerator_t hiprandGenerator_t
#endif
#ifndef curandStatus_t
#define curandStatus_t hiprandStatus_t
#endif

// macros, constants, enums
#ifndef CURAND_RNG_PSEUDO_DEFAULT
#define CURAND_RNG_PSEUDO_DEFAULT HIPRAND_RNG_PSEUDO_DEFAULT
#endif
#ifndef CURAND_STATUS_SUCCESS
#define CURAND_STATUS_SUCCESS HIPRAND_STATUS_SUCCESS
#endif
#ifndef CURAND_RNG_PSEUDO_PHILOX4_32_10
#define CURAND_RNG_PSEUDO_PHILOX4_32_10 HIPRAND_RNG_PSEUDO_PHILOX4_32_10
#endif

// functions
#ifndef curandCreateGenerator
#define curandCreateGenerator hiprandCreateGenerator
#endif
#ifndef curandDestroyGenerator
#define curandDestroyGenerator hiprandDestroyGenerator
#endif
#ifndef curandGenerateNormal
#define curandGenerateNormal hiprandGenerateNormal
#endif
#ifndef curandGenerateNormalDouble
#define curandGenerateNormalDouble hiprandGenerateNormalDouble
#endif
#ifndef curandSetPseudoRandomGeneratorSeed
#define curandSetPseudoRandomGeneratorSeed hiprandSetPseudoRandomGeneratorSeed
#endif
#ifndef curandGenerateUniform
#define curandGenerateUniform hiprandGenerateUniform
#endif
#ifndef curandGenerateUniformDouble
#define curandGenerateUniformDouble hiprandGenerateUniformDouble
#endif

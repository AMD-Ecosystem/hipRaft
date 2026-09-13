# Changelog

hipRAFT is AMD's port of NVIDIA's RAFT library, enabling RAFT on AMD GPUs using the HIP platform.

<!---
    MIT License

    Modifications Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
-->

## [Release Version 2.0.0] - 2026-09-30

### Features
- Upgraded upstream RAFT baseline from 25.10 to 26.06, incorporating new upstream primitives, performance improvements, and API changes
- ROCm 10.0.0 support
- Added PCA and truncated SVD primitives (`raft::linalg::pca`, `raft::linalg::tsvd`), moved from cuML into RAFT upstream
- Added sparse randomized SVD solvers (`raft::sparse::solver::randomized_svds`)
- Exposed the `numpy_serializer` helpers as public APIs
- Migrated memory resource handling to the unified CCCL memory-resource design, including tracking memory resources
- Python wheels published on AMD PyPI as `amd-libraft` and `amd-pylibraft` for Python 3.11, 3.12, and 3.13

### Bug Fixes
- Fall back to plain `gemm` when hipBLASLt reports that no algorithm is available
- Avoid a constant division by zero in the histogram `computeGridDim` path
- Correct the ROCm version guard for the `constexpr` half-precision workaround
- Clamp negative eigenvalues in the `rsvdFixedRank` BBt path, which produced `NaN` results on gfx942
- Keep the previous global device memory resource alive in the memory-tracking resources
- Resolve the Tensile library path per GPU architecture instead of using the parent directory
- Use a HIP shim for `cudaStreamPerThread` in `handle.pyx`
- Fix the gfx90a build against the upstream 26.06 baseline
- Add a missing stream synchronization in the half-precision transpose tests

### Build & Infrastructure
- Bump hipMM from 4.0.0 to 5.0.0 and ROCmDS-Logger from 1.0.0 to 2.0.0
- Migrate the Python packages to the `scikit-build-core` build backend
- Replace the `hip-python` dependencies with `rocm-bindings-hip` and `hip-python-interop`
- Relocate upstream CI, devcontainer, and conda files under `.upstream/`
- Promote the rocPRIM, hipCUB, rocThrust, and CCCL/hipCCL CMake targets to global scope
- Update the conda environments to Python 3.11, `cython>=3.2.2`, and add `ninja`

### Limitations
- Multi-Node / Multi GPU is experimental
- Raft-dask is experimental
- `raft::linalg::randomized_svd` is not supported; it requires a hipSOLVER equivalent of `cusolverDnXgesvdr`
- `raft::sparse::linalg::masked_matmul` is not supported for the `half` type
- `raft::random::make_regression` is not supported for the `double` type
- The APIs in `raft/core/interruptible.hpp` are not supported

## [Release Version 1.0.0] - 2026-04-01

### Features
- Upgraded upstream RAFT baseline from 25.02 to 25.10, incorporating new upstream primitives, performance improvements, and API changes
- Added support for gfx950 AMD GPU architectures
- Implement `RAFT_CUDA_TRY` error-checking macro for HIP runtime API calls, ensuring consistent error propagation on AMD GPUs
- Port NN Descent graph construction kernel with wavefront-size-64 compatibility, adapting warp-synchronous primitives for CDNA architecture
- Improve hipBLASLt GEMM device pointer mode handling to account for unsupported `HIPBLASLT_POINTER_MODE_ALPHA_DEVICE_VECTOR_BETA_HOST` mode

### Bug Fixes
- Fix OpenMP thread pool cleanup ordering to prevent HIP TLS (thread-local storage) destructor segfault at process exit
- Resolve `constexpr` half-precision (`__half`) construction failure under HIP/AMD by using runtime initialization path
- Work around hipBLASLt unsupported device pointer mode in GEMM unit tests by falling back to host pointer mode
- Correct MST (Minimum Spanning Tree) solver for 64-wide wavefront execution, fixing reduction and ballot intrinsics
- Resolve `Copy2DAsync` test race condition caused by missing stream synchronization before host-side validation
- Fix missing RCCL header include path in `nccl_comm.hpp`
- Zero-initialize input buffer margins in `gather` test kernels to eliminate non-deterministic read-of-uninitialized failures
- Fix incorrect eigenvalue ordering in `lanczos_smallest` solver caused by off-by-one in Ritz value selection
- Zero-initialize output bins in `histogram.cu` to prevent accumulation of stale values across repeated kernel launches
- Enable `hip::std::optional` in neighborhood recall computation to replace missing `cuda::std::optional` on HIP

### Build & Infrastructure
- Switch HIP backend to `-fopenmp` compiler flags while preserving `FindOpenMP` CMake module for CUDA path
- Update dependency branch names in versions.json
- Bump ROCm base version to 7.2.1 in build infrastructure
- Suppress `-Wdeprecated` and `-Wsign-compare` warnings when compiling gtest under hipcc
- Fix pre-commit CMakeLists formatting violations

### Limitations
- Multi-Node/ Multi GPU is experimental
- Raft-dask is experimental

## [Initial Release Version 0.1.0] - 2025-11-04

### Platform Support
- Complete hipification of RAFT codebase for AMD GPUs
- ROCm 7.0.2 support with HIP platform
- AMD-specific optimizations (64-thread wavefront vs NVIDIA's 32)
- Integration with ROCm-DS ecosystem
- Build system overhaul for HIP/ROCm with CMake and CPack
- Support for multiple AMD GPU architectures (gfx90a, gfx942)

### Accelerated Functions in hipRAFT
- **Linear algebra & matrix ops**: BLAS routines (axpy, dot, gemm/gemv), mapping/reduction (map, map_reduce, norms, normalize, reduce), transposes, select-k, etc.
- **Solvers**: iterative/combinatorial solver primitives.
- **Sparse:** linear algebra, eigenvalue problems, slicing, norms, reductions, factorization, symmetrization, components & labeling
- **Dense Operations:**  linear algebra, matrix and vector operations, reductions, slicing, norms, factorization, least squares, svd & eigenvalue problems
- **Stats**: summary statistics, probability & information-theory metrics, regression/classification/clustering model scoring utilities.
- **Core/Utilities**: device resource management, streams, operators/functors

### Language Bindings
- **C++:** Native templates and headers with examples
- **Python:** Cython bindings and examples

### Key Technical Changes
- Wavefront size adaptations (32→64 threads)
- Fixed uninitialized shared memory and bounds checking issues
- Optimized kernel launch parameters and LDS memory access for AMD GPUs
- Platform-specific intrinsic replacements (CUDA→HIP)
- Examples for C++ and Python
- Additional thread safety

### Limitations
- Multi-Node/ Multi GPU is experimental
- Raft-dask is unsupported

### Contributors
- Philipp Samfass, Lalith Narasimhan, Sujin Philip, Sukriti Choudhary, Grant Pinkert, Kevin Joseph, Randy Hartgrove, Alex Xu

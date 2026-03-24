# Changelog

hipRAFT is AMD's port of NVIDIA's RAFT library, enabling RAFT on AMD GPUs using the HIP platform.

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

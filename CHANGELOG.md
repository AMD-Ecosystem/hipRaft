# Changelog

hipRAFT is AMD's port of NVIDIA's RAFT library, enabling 25.02 version of RAFT on AMD GPUs using the HIP platform.

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
- Philipp Samfass, Lalith Narasimhan, Sujin Philip, Sukriti Choudhary, Grant Pinkert, Kevin Joseph, Randy Hartgrove, Alex Xu,

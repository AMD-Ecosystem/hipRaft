# HIP Reusable Accelerated Functions and Tools for Vector Search and More (hipRAFT)

> This ROCm&trade;/HIP&trade; port is derived from the NVIDIA RAPIDS&reg; RAFT project. It aims to

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

follow the latter's directory structure, file naming and API naming as closely as possible to
minimize porting friction for users that are interested in using both projects.

hipRAFT is a library of fundamental algorithms and primitives for machine-learning and data-mining workloads that can be run on AMD GPUs. Forked from the [raft](https://github.com/rapidsai/raft) project, hipRAFT brings the same rich functionality to the HIP&trade;/ROCm&trade; stack while preserving the familiar API. It offers both a modern C++ interface for systems developers and fully featured Python bindings for rapid prototyping and data-science workflows.



While not exhaustive, the following table summarizes the accelerated functions in hipRAFT:

| Module     | Headers                     | Summary                                                                                                                                                                                                                                                                                                                                | Known Limitations                                                       |
|------------|-----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------|
| **Core**   | `cpp/include/raft/core/*`   | <ul><li>Spans, buffers, and memory allocation policies and containers.</li><li>GPU Resource Management – Streams, events, device properties.</li><li>Logging & Debugging – Logging macros, profiling utilities.</li><li>Sparse Dense Matrix Abstractions– COO and CSR matrix handling.</li></ul>                                       | The API's in `raft/core/interruptible.hpp` are not supported.           |
| **Label**  | `cpp/include/raft/label/*`  | These API's provide functionalities for handling and processing class labels in machine learning and graph-based algorithms. They focus on extracting unique labels, mapping labels to a monotonically increasing order, and merging different label sets.                                                                             | None                                                                    |
| **Linalg** | `cpp/include/raft/linalg/*` | API's that abstract common BLAS routines, standard linear system solvers, factorization and eigenvalue solvers.                                                                                                                                                                                                                        | `raft::linalg::randomized_svd` is not supported.                        |
| **Matrix** | `cpp/include/raft/matrix/*` | hipRAFT's matrix API extends matrix operations beyond `raft::linalg`, offering utilities for arithmetic (power, ratio, reciprocal, sign-flip, square root), manipulation (initialization, reversing, thresholding), ordering (argmax, argmin, select-K, sorting), and reductions (matrix norms).                                       | None                                                                    |
| **Solver** | `cpp/include/raft/solver/*` | Solvers supported: <ul><li>`LinearAssignmentProblem` solver(alternating tree Hungarian Algorithm) from `cpp/include/raft/solver/linear_assignment.cuh`</li><li>`Minimum spanning tree` solver is supported from `cpp/include/raft/sparse/mst/mst.hpp`</li></ul>                                                                   | None                                                                    |
| **Sparse** | `cpp/include/raft/sparse/*` | hipRAFT's Sparse module provides GPU-accelerated operations for sparse matrices, including arithmetic, normalization, multiplication, slicing, and solvers for eigenvalues and graph problems, optimizing large-scale computations.                                                                                                    | `raft::sparse::linalg::masked_matmul` is not supported for `half` type. |
| **Util**   | `cpp/include/raft/util/*`   | Miscellaneous utility/helper functions                                                                                                                                                                                                                                                                                                 | None                                                                    |
| **Common** | `cpp/include/raft/common/*` | Miscellaneous common functions used across various modules.                                                                                                                                                                                                                                                                            | None                                                                    |
| **Random** | `cpp/include/raft/random/*` | Miscellaneous functions for random number generation.                                                                                                                                                                                                                                                                                  | `raft::random::make_regression` is not supported for the `double` type. |
<hr>

## Useful Resources

- [hipRAFT Documentation](https://rocm.docs.amd.com/projects/hipRaft/en/latest/): API documentation.
- [System requirements](https://rocm.docs.amd.com/projects/hipRaft/en/latest/install/system-requirements.html): Supported ROCm versions, operating systems, AMD GPUs, and Python versions.
- [Install hipRAFT](https://rocm.docs.amd.com/projects/hipRaft/en/latest/install/install.html): Instructions for installing hipRAFT from AMD PyPI.
- [Build hipRAFT](https://rocm.docs.amd.com/projects/hipRaft/en/latest/install/build.html): Instructions for building hipRAFT from source.
- [AMD Data Science](https://rocm.docs.amd.com/projects/rocm-ds/en/latest/): The toolkit that hipRAFT is part of.
- [GitHub repository](https://github.com/AMD-AIOSS/hipRaft): Download the hipRAFT source code.
- [Issue tracker](https://github.com/AMD-AIOSS/hipRaft/issues): Report issues or request features.
- [Upstream RAFT](https://github.com/rapidsai/raft): The NVIDIA RAPIDS project that hipRAFT is derived from.



## What is hipRAFT?

hipRAFT contains fundamental widely-used algorithms and primitives for machine learning and data mining. The algorithms are GPU-accelerated with HIP and form building blocks for more easily writing high performance applications.

By taking a primitives-based approach to algorithm development, hipRAFT
- accelerates algorithm construction time
- reduces the maintenance burden by maximizing reuse across projects, and
- centralizes core reusable computations, allowing future optimizations to benefit all algorithms that use them.

While not exhaustive, the following general categories help summarize the accelerated functions in hipRAFT:
#####
| Category              | Accelerated Functions in hipRAFT                                                                                                  |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| **Data Formats**      | sparse & dense, conversions, data generation                                                                                      |
| **Dense Operations**  | linear algebra, matrix and vector operations, reductions, slicing, norms, factorization, least squares, svd & eigenvalue problems |
| **Sparse Operations** | linear algebra, eigenvalue problems, slicing, norms, reductions, factorization, symmetrization, components & labeling             |
| **Solvers**           | combinatorial optimization, iterative solvers                                                                                     |
| **Statistics**        | sampling, moments and summary statistics, metrics, model evaluation                                                               |
| **Tools & Utilities** | common tools and utilities for developing HIP applications, multi-node multi-gpu infrastructure                                   |


hipRAFT is a C++ header-only template library with an optional shared library that
1) can speed up compile times for common template types, and
2) provides host-accessible "runtime" APIs, which don't require a HIP compiler to use

In addition being a C++ library, hipRAFT also provides 2 Python libraries:
- `pylibraft` - lightweight Python wrappers around hipRAFT's host-accessible "runtime" APIs.
- `raft-dask` - multi-node multi-GPU communicator infrastructure for building distributed algorithms on the GPU with Dask. This package is experimental and has limited testing.

![hipRAFT is a C++ header-only template library with optional shared library and lightweight Python wrappers](https://raw.githubusercontent.com/rapidsai/raft/HEAD/img/arch.png)


## Is hipRAFT right for me?

hipRAFT contains low-level primitives for accelerating applications and workflows. Data source providers and application developers may find specific tools very useful. hipRAFT is not intended to be used directly by data scientists for discovery and experimentation. For data science tools, please see the [AMD Data Science](https://rocm.docs.amd.com/projects/rocm-ds/en/latest/) documentation.

## Getting started

### Memory management (hipMM)

hipRAFT relies heavily on hipMM, AMD's port of the RAPIDS Memory Manager (RMM), which eases the burden of configuring different allocation strategies globally across the libraries that use it.

### Multi-dimensional Arrays

The APIs in hipRAFT accept the [mdspan](https://arxiv.org/abs/2010.06474) multi-dimensional array view for representing data in higher dimensions similar to the `ndarray` in the Numpy Python library. hipRAFT also contains the corresponding owning `mdarray` structure, which simplifies the allocation and management of multi-dimensional data in both host and device (GPU) memory.

The `mdarray` forms a convenience layer over hipMM and can be constructed in hipRAFT using a number of different helper functions:

```c++
#include <raft/core/device_mdarray.hpp>

int n_rows = 10;
int n_cols = 10;

auto scalar = raft::make_device_scalar<float>(handle, 1.0);
auto vector = raft::make_device_vector<float>(handle, n_cols);
auto matrix = raft::make_device_matrix<float>(handle, n_rows, n_cols);
```

### C++ Example

Most of the primitives in hipRAFT accept a `raft::device_resources` object for the management of resources which are expensive to create, such as HIP streams, stream pools, and handles to other ROCm libraries like hipBLAS and hipSOLVER.

The example below demonstrates creating a hipRAFT handle and using it with `device_matrix` and `device_vector` to allocate memory, generating random clusters, and computing
pairwise Euclidean distances with the [hipVS](https://github.com/AMD-AIOSS/hipVS) library. hipVS preserves the cuVS API naming, so the `cuvs::` namespace is used here as well:

```c++
#include <raft/core/device_resources.hpp>
#include <raft/core/device_mdspan.hpp>
#include <raft/random/make_blobs.cuh>
#include <cuvs/distance/distance.hpp>

raft::device_resources handle;

int n_samples = 5000;
int n_features = 50;

float *input;
int *labels;
float *output;

...
// Allocate input, labels, and output pointers
...

auto input_view = raft::make_device_matrix_view(input, n_samples, n_features);
auto labels_view = raft::make_device_vector_view(labels, n_samples);
auto output_view = raft::make_device_matrix_view(output, n_samples, n_samples);

raft::random::make_blobs(handle, input_view, labels_view);

auto metric = cuvs::distance::DistanceType::L2SqrtExpanded;
cuvs::distance::pairwise_distance(handle, input_view, input_view, output_view, metric);
```


### Python Example

The `pylibraft` package contains a Python API for hipRAFT algorithms and primitives. `pylibraft` integrates nicely into other libraries by being very lightweight with minimal dependencies and accepting any object that supports the `__cuda_array_interface__`, which on AMD GPUs is backed by HIP. The number of hipRAFT algorithms exposed in this package is continuing to grow from release to release.

The example below demonstrates computing the pairwise Euclidean distances between CuPy arrays using the [hipVS](https://github.com/AMD-AIOSS/hipVS) library. Note that CuPy is not a required dependency for `pylibraft`.

```python
import cupy as cp

from cuvs.distance import pairwise_distance

n_samples = 5000
n_features = 50

in1 = cp.random.random_sample((n_samples, n_features), dtype=cp.float32)
in2 = cp.random.random_sample((n_samples, n_features), dtype=cp.float32)

output = pairwise_distance(in1, in2, metric="euclidean")
```

The `output` array in the above example is of type `raft.common.device_ndarray`, which supports [__cuda_array_interface__](https://numba.pydata.org/numba-doc/dev/cuda/cuda_array_interface.html#cuda-array-interface-version-2) making it interoperable with other libraries like CuPy, Numba, PyTorch and RAPIDS cuDF that also support it. CuPy supports DLPack, which also enables zero-copy conversion from `raft.common.device_ndarray` to JAX and Tensorflow.

Below is an example of converting the output `pylibraft.device_ndarray` to a CuPy array:
```python
cupy_array = cp.asarray(output)
```

And converting to a PyTorch tensor:
```python
import torch

torch_tensor = torch.as_tensor(output, device='cuda')
```

Or converting to a RAPIDS cuDF dataframe:
```python
cudf_dataframe = cudf.DataFrame(output)
```

When the corresponding library has been installed and available in your environment, this conversion can also be done automatically by all hipRAFT compute APIs by setting a global configuration option:
```python
import pylibraft.config
pylibraft.config.set_output_as("cupy")  # All compute APIs will return cupy arrays
pylibraft.config.set_output_as("torch") # All compute APIs will return torch tensors
```

You can also specify a `callable` that accepts a `pylibraft.common.device_ndarray` and performs a custom conversion. The following example converts all output to `numpy` arrays:
```python
pylibraft.config.set_output_as(lambda device_ndarray: return device_ndarray.copy_to_host())
```

`pylibraft` also supports writing to a pre-allocated output array so any `__cuda_array_interface__` supported array can be written to in-place:

```python
import cupy as cp

from cuvs.distance import pairwise_distance

n_samples = 5000
n_features = 50

in1 = cp.random.random_sample((n_samples, n_features), dtype=cp.float32)
in2 = cp.random.random_sample((n_samples, n_features), dtype=cp.float32)
output = cp.empty((n_samples, n_samples), dtype=cp.float32)

pairwise_distance(in1, in2, out=output, metric="euclidean")
```


## Installing

hipRAFT is distributed through [AMD PyPI](https://pypi.amd.com/rocm-10.0.0/simple/). Before installing, see the
[system requirements](https://rocm.docs.amd.com/projects/hipRaft/en/latest/install/system-requirements.html)
for the supported ROCm versions, operating systems, AMD GPUs, and Python versions.

Two packages are published:

| Package | Contents |
|---------|----------|
| `amd-libraft` | The hipRAFT C++ headers and the `libraft` shared library. |
| `amd-pylibraft` | The Python bindings. Installing this package pulls in a matching `amd-libraft`. |

Create and activate an environment with a supported Python version, then install with pip:

```bash
conda create --name hipraft python=3.12 # Specify your Python version
conda activate hipraft

pip install amd-pylibraft==2.0.0 --extra-index-url=https://pypi.amd.com/rocm-10.0.0/simple/
```

Installing `amd-pylibraft` is sufficient for Python workloads. To install only the C++ artifacts,
for example when building a downstream C++ project against hipRAFT, install `amd-libraft` on its own:

```bash
pip install amd-libraft==2.0.0 --extra-index-url=https://pypi.amd.com/rocm-10.0.0/simple/
```

The [build instructions](https://rocm.docs.amd.com/projects/hipRaft/en/latest/install/build.html) contain
more details on building hipRAFT from source and including it in downstream projects.


## Contributing

If you are interested in contributing to the hipRAFT project, refer to
[Contributing to AMD Data Science](https://rocm.docs.amd.com/projects/rocm-ds/en/latest/contribute/contributing.html).
The upstream RAFT [developer guide](.upstream/docs/source/developer_guide.md) documents the coding
guidelines, workflows, and principles that hipRAFT continues to follow.

## References

hipRAFT is derived from the RAPIDS RAFT project. When citing RAFT generally, please consider referencing this Github project.
```bibtex
@misc{rapidsai,
  title={Rapidsai/raft: RAFT contains fundamental widely-used algorithms and primitives for data science, Graph and machine learning.},
  url={https://github.com/rapidsai/raft},
  journal={GitHub},
  publisher={NVIDIA RAPIDS},
  author={Rapidsai},
  year={2022}
}
```

<!---
---
myst:
  html_meta:
    "description": "hipRAFT documentation and API reference library"
    "keywords": "Machine-Learning, Information-Retrieval, Primitives, Nearest-Neighbors, GPU, RAPIDS, ROCm-DS"
---
-->

# Using hipRAFT

Example code demonstrating the use of the hipRAFT library is provided
in the `hipRaft/examples` folder. Both C++ and Python examples are provided. These
example projects can be used as templates to build your own application using
hipRAFT or to add hipRAFT to existing projects.

# C++ examples

To build the C++ examples, use the provided `build.sh` script. This is a bash script
that calls the appropriate CMake commands, so you can look into it to see the typical
CMake based build workflow.

The C++ examples use the `libraft` library. The CMake scripts will automatically download the
latest release and build it. There are some pre-requisites for building the library. Refer to the
[Building hipRAFT from source](../install/build.md#building-hipraft-from-source) documentation
for instructions on how to set up your developer environment for building hipRAFT.

The directory `<raft_source>/examples/cpp`, can be copied directly and used as a starting point
to build a new application with hipRAFT. An existing CMake project can also be modified to
use hipRAFT by copying the contents in the "configure rapids-cmake" and "configure raft" sections
of the provided CMakeLists.txt into your project, along with the
`cmake/thirdparty/fetch_rapids.cmake` and `cmake/thirdparty/get_raft.cmake` files.

To build against a version other than the latest release, set the CMake variable
`RAFT_PINNED_TAG`, in `get_raft.cmake`, to the branch to build against. Alternatively, the
CMake variable `CPM_raft_SOURCE` can be set to a local directory containing
the hipRAFT source code, possibly with custom code changes that you want to test.

Be sure to link against the appropriate CMake targets. Use `raft::raft` to make the headers
available and `raft::compiled` when utilizing the shared library.

```CMake
target_link_libraries(your_app_target PRIVATE raft::raft raft::compiled)
```

## Linear Algebra (linalg) example

This example demonstrates the use of the `linalg` module. It generates a random
matrix and a random vector and computes their product using:

1. [raft::linalg::dot](reference/cpp_api/linalg_blas:dot), to take the dot product of each row of the matrix with the vector
to produce each element of the result vector.
2. [raft::linalg::gemv](reference/cpp_api/linalg_blas:gemv), to compute the product directly.

The results of the two methods are then compared using [raft::linalg::mean_squared_error](linalg-mean-squared-error).

It should produce an output like:

```
$ ./examples/build/LINALG_EXAMPLE
Mean Squared Error: 6.81184e-13
```

## Make Blobs example

This example demonstrates the `make_blobs` function in the `random` module. Several random
2D clusters are generated in the form of a sparse matrix. The sparse matrix is then converted to
a dense 2D map using a custom HIP kernel, and printed on the screen. The output should look
something like this:

```
$ ./examples/build/MAKE_BLOBS_EXAMPLE
seed: 1140758900
.........................................
.........................................
................444.4....................
.............4...4444....................
..1...........4.44444.4..................
1.1.1.1..........44.4....................
1..1.1..1........44......................
.111111.............4....................
00101.1.1................................
000.11...................................
000000...................................
0..0.....................................
.0.0.....................................
.........................................
........2................................
..........2..............................
.......2...222...........................
......22222222.2.........................
......2.222.2222.........3333............
...........2222.......3.333333...........
.............2...........333..3..........
```

This example also demonstrates hipRAFT inter-op with custom HIP kernels and rocThrust.

# Python example

The Python example depends on the `pylibraft` module, which can either be installed
using pip or built from source following the instructions in [Building hipRAFT from source](../install/build.md#python-library).
The example generates a random directed-graph using the [pylibraft.random.rmat](reference/pylibraft_api/random:random) function. The
generated graph is printed on the screen as an adjacency list. The output should look something like:

```
$ python3 ./examples/python/rmat_example.py
number of self-loops: 4
number of duplicates: 20
Graph Adjacency List:
64 : {68, 78}
169 : {96, 33, 4, 69, 36, 37, 40, 9, 102, 11, 76, 45, 110, 12, 27, 31, 101, 95}
240 : {112, 48, 82, 116, 52}
191 : {65, 116}
48 : {18, 84, 122, 27, 28}
49 : {97, 60, 124, 113, 18, 25, 28, 93}
229 : {88, 39, 119}
243 : {104, 16, 122}
179 : {98, 92, 60, 125, 30}
9 : {33, 69, 8, 41, 123}
...
52 : {126}
121 : {29}
```

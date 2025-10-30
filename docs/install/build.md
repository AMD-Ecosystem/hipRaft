# Building hipRAFT from source

hipRAFT currently provides C++ and Python APIs. The following instructions provide steps to build and test hipRAFT from source files provided in the [https://github.com/ROCm-DS/hipRaft](https://github.com/ROCm-DS/hipRaft) repository. 

## Tested on the following GPUs

| AMD Instinct GPU    | Architecture | Wavefront Size | LLVM target |
|---------------------|--------------|----------------|-------------|
| MI210               | CDNA2        | 64             | gfx90a      |
| MI250               | CDNA2        | 64             | gfx90a      |
| MI250X              | CDNA2        | 64             | gfx90a      |
| MI300A              | CDNA3        | 64             | gfx942      |
| MI300X              | CDNA3        | 64             | gfx942      |

## Dependencies

hipRAFT builds against the AMD ROCm software stack, that is the ROCm runtime, HIP compiler tool-chain, and a GPU driver that matches your ROCm version.

Install ROCm 7.0.2 or later, or the minimum version supported by the GPUs listed above, and make sure the `rocminfo` and `hipcc` commands are in your `PATH`. For more information, see [ROCm Installation](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/).

| Name                                                                  | Version / Notes                              |
| ----------------------------------------------------------            | -------------------------------------------- |
| [`cmake`](https://cmake.org/)                                         | ≥ 3.31.0                                     |
| [`ninja`](https://ninja-build.org/)                                   | ≥ 1.11.1                                     |
| [`hipsolver`](https://rocm.docs.amd.com/projects/hipSOLVER/en/latest/)| Version that comes bundled with ROCm ≥ 7.0.2 |
| [`hipblas`](https://rocm.docs.amd.com/projects/hipBLAS/en/latest/)    | Version that comes bundled with ROCm ≥ 7.0.2 |
| [`hipblaslt`](https://rocm.docs.amd.com/projects/hipBLASLt/en/latest/)| Version that comes bundled with ROCm ≥ 7.0.2 |
| [`hiprand`](https://rocm.docs.amd.com/projects/hipRAND/en/latest/)    | Version that comes bundled with ROCm ≥ 7.0.2 |
| [`hipsparse`](https://rocm.docs.amd.com/projects/hipSPARSE/en/latest/)| Version that comes bundled with ROCm ≥ 7.0.2 |
| [`libblas-dev`](https://www.netlib.org/lapack/)                       | Tested with 3.12.0                           |
| [`liblapack-dev`](https://www.netlib.org/lapack/)                     | Tested with 3.12.0                           |
| [`SuiteSparse`](https://github.com/DrTimothyAldenDavis/SuiteSparse)   | Tested with 7.6.1                            |
| **Additional Required Dependencies**                                                                                 |
| **\***[`hipMM`](https://github.com/ROCm-DS/hipMM)                     | 3.0.0                                        |
| **\***[`hipCollections`](https://github.com/ROCm/hipCollections)      | 0.3.0                                        |
| **\***[`libhipcxx`](https://github.com/ROCm/libhipcxx)                | 2.7.0                                        |
| **\***[`hipCUB`](https://github.com/ROCm/hipCUB)                      | Version that comes bundled with ROCm ≥ 7.0.2 |
| **\***[`rocThrust`](https://github.com/ROCm/rocThrust)                | Version that comes bundled with ROCm ≥ 7.0.2 |
| **\*\***[`OpenMP`](https://www.openmp.org/)                           | Version that comes bundled with ROCm ≥ 7.0.2 |
| **Optional Dependencies**                                                                                            |
| [`RCCL`](https://rocm.docs.amd.com/projects/rccl/en/latest/)          | Version that comes bundled with ROCm ≥ 7.0.2 |
| [`UCX`](https://github.com/openucx/ucx)                               | ≥ 1.17.0                                     |
| [`Googletest`](https://github.com/google/googletest)                  | ≥ 1.13.0                                     |
| [`Googlebench`](https://github.com/google/benchmark)                  | ≥ 1.13.0                                     |
| [`Doxygen`](https://github.com/doxygen/doxygen)                       | >=1.8.20                                     |

> `*` - If not found locally the CMake build system will attempt to download a compatible version using [ROCmDS-cmake](https://github.com/ROCm-DS/ROCmDS-cmake). 
>
> `**` - The `OpenMP` toolchain is automatically installed as part of the standard ROCm installation and is available under /`opt/rocm-{version}/llvm`.

### Docker

hipRAFT also provides a `Dockerfile` that encapsulates all the above dependencies for development. The following are the instructions to create a container using this Dockerfile.

```bash
cd <REPO_ROOT>
# If BuildKit is not available.
DOCKER_BUILDKIT=1 docker build -t <RAFT_DEV_IMAGE> .
# If BuildKit is available: "docker buildx build  -t  <RAFT_DEV_IMAGE> ."
docker run -d -it --cap-add=SYS_PTRACE \
       --device=/dev/kfd \
       --device=/dev/dri \
       --group-add=video \
       --ipc=host \
       --name <CONTAINER_NAME> \
       --init \
       --network=host \
       --security-opt seccomp=unconfined \
       -v <REPO_ROOT>:<REPO_ROOT> <RAFT_DEV_IMAGE>  tail -f /dev/null
docker exec -it <CONTAINER_NAME> bash
```
This container will have all necessary packages installed to build and run hipRAFT. The preceding command will create an Ubuntu 24.04 container that has ROCm installed. To use Ubuntu 22.04, replace the Docker build command with the following:

```bash
docker build --build-arg UBUNTU=22.04 -t <RAFT_DEV_IMAGE> .
```

## Environment variables

```bash
export CMAKE_PREFIX_PATH=/opt/rocm/lib/cmake # Set CMAKE_PREFIX_PATH to point to the ROCm installation site
```

## C++ library

### Header-only C++

`build.sh` uses [ROCmDS-cmake](https://github.com/ROCm-DS/ROCmDS-cmake), which will automatically download any dependencies that are not already installed.

The following example will download the needed dependencies and install the hipRAFT headers into `$INSTALL_PREFIX/include/hipRAFT`.

```bash
./build.sh libraft
```

The `-n` flag can be passed to have the build download just the needed dependencies. Because hipRAFT C++ headers are primarily used during build-time in downstream projects, the dependencies will never be installed by the hipRAFT build.

```bash
./build.sh libraft -n
```

After installation, `libraft` headers (and dependencies which were downloaded and installed using `ROCmDS-cmake`) can be uninstalled also using `build.sh`:

```bash
./build.sh libraft --uninstall
```

### C++ Shared Library (optional)

A shared library must be built in order to build `pylibraft`. Pass the `--compile-lib` flag to `build.sh` to build the library:

```bash
./build.sh libraft --compile-lib
```

In the preceding example the shared library is installed by default into `$INSTALL_PREFIX/lib`. To disable this, pass `-n` flag.

Once installed, the shared library, headers (and any dependencies downloaded and installed via `ROCmDS-cmake`) can be uninstalled using `build.sh`:

```bash
./build.sh libraft --uninstall
```

### C++ Tests

Compile the tests using the `tests` target in `build.sh`.

```bash
./build.sh libraft tests
```

The tests are broken apart by algorithm category, so you will find several binaries in `cpp/build/gtests` named `*_TEST`.

For example, to run the matrix tests:
```bash
./cpp/build/gtests/MATRIX_TEST
```

It can take significant time to compile all of the tests. You can build individual tests by providing a semicolon-separated list to the `--limit-tests` option in `build.sh`:

```bash
./build.sh libraft tests -n --limit-tests="CORE_TEST;MATRIX_TEST"
```

Running all the C++ tests using ctest:
```bash
cd ./cpp/build/
ctest --test-dir ./tests # If "--limit-tests" is specified, only a subset of tests are built. To run all the tests remove "--limit-tests" when building through `build.sh`
```

### ccache and sccache

[`ccache`](https://ccache.dev/) and [`sccache`](https://github.com/mozilla/sccache) can be used to better cache parts of the build when rebuilding frequently, such as when working on a new feature. You can also use `ccache` or `sccache` with `build.sh`:

```bash
./build.sh libraft --cache-tool=ccache
```

### Using CMake directly

When building hipRAFT from source, the `build.sh` script provides a convenient wrapper around the `cmake` commands to ease the burdens of manually configuring the various available cmake options. When more fine-grained control over the CMake configuration is desired, the `cmake` command can be invoked directly as the following example demonstrates.

The `CMAKE_INSTALL_PREFIX` option instructs CMake to install hipRAFT into a specific location.

```bash
cd <HIPRAFT_ROOT>/cpp
mkdir -p build && rm -rf build/*
cd build
# Configuration stage
cmake -S .. \
      -G Ninja \
      -B . \
      -DCMAKE_INSTALL_PREFIX=install \
      -DCMAKE_HIP_ARCHITECTURES=NATIVE \
      -DCMAKE_BUILD_TYPE=Release \
      -DRAFT_COMPILE_LIBRARY=ON \
      -DBUILD_TESTS=ON \
      -DCMAKE_CXX_COMPILER=hipcc
# Build all targets
ninja
# Install
ninja install
```

For hipRAFT, CMake has the following configurable flags available:

| Flag                      | Possible Values                     | Default Value | Behavior                                                                                                                                                            |
|---------------------------|-------------------------------------| --------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| CMAKE_HIP_ARCHITECTURES   | NATIVE or specific GPU architectures| NATIVE        | NATIVE to compile for the automatically detected GPU on the system. Can also specify `;` delimited list of specific architectures. Example: `gfx942;gfx90a`        |
| BUILD_TESTS               | ON, OFF                             | ON            | Compile Googletests                                                                                                                                                 |
| DETECT_CONDA_ENV          | ON, OFF                             | ON            | Enable detection of conda environment for dependencies                                                                                                              |
| RAFT_COMPILE_LIBRARY      | ON, OFF                             | ON if either BUILD_TESTS or BUILD_PRIMS_BENCH is ON; otherwise OFF | Compiles all `libraft` shared libraries (these are required for Googletests)                                   |
| RAFT_COMPILE_DYNAMIC_ONLY | ON, OFF                             | OFF           | Only build the shared library and skip the static library. Has no effect if RAFT_COMPILE_LIBRARY is OFF                                                             |

### GPU Architecture selection

#### --allgpuarch

Builds hipRAFT for all supported GPU architectures, increasing portability but also build time. You can also use `--allgpuarch` with `build.sh`.

```bash
./build.sh clean
./build.sh libraft tests --allgpuarch
```

> **Note** 
> Always execute a clean build or manually delete the build directory before running this argument if a previous build is present, to prevent potential build conflicts or errors.

#### Compile only for specified GPU arch

When specifying target architectures, provide them as a single string enclosed in double quotes. For multiple architectures, separate each with a semicolon (`;`).

```bash
./build.sh libraft tests --gpu-arch="gfx90a;gfx942"
```

OR

```bash
./build.sh libraft tests --gpu-arch="gfx942"
```

> **Note**
> Do not specify both `--gpu-arch` and `--allgpuarch` flags in the same build command. Avoid using multiple separate `--gpu-arch` flags by combining all target architectures into one `--gpu-arch` option.

## Python Library

### Conda environment scripts

Conda environment scripts are provided for installing the necessary dependencies to build the Python libraries from source. It is preferred to use [`micromamba`](https://github.com/mamba-org/mamba) as it's a fully statically-linked, self-contained, executable. `micromamba` can be installed by following the instructions on this page: [Micromamba Installation](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html).

```bash
micromamba  env create --name pylibraft  --file conda/environments/all_rocm_arch-x86_64.yaml
# To initialize the current bash shell, run:
eval "$(micromamba shell hook --shell bash)"
micromamba activate pylibraft
```
It is recommended to build the python wheels in a conda environment built from `all_rocm_arch-x86_64.yaml`. It is also possible to use `venv` but it is up to the user to install all the required packages in the environment.

### Building and installing `pylibraft`
The Python libraries can be built and installed using the build.sh script:

```bash
# Activate environment created above.
micromamba activate pylibraft

# Build and install pylibraft and required dependencies.
./build.sh libraft pylibraft --compile-lib

# Test installation
python
>> import pylibraft
```

Building and installing the python wheels manually:
```bash
# Build libraft python wheel
cd <HIPRAFT_ROOT>/python/libraft/
pip wheel -w dist -v --no-build-isolation --disable-pip-version-check .
# Install libraft wheel
pip install dist/libraft-*.whl

# Build pylibraft python wheel
cd <HIPRAFT_ROOT>/python/pylibraft/
pip wheel -w dist -v --no-build-isolation --disable-pip-version-check .
# Install pylibraft wheel
pip install dist/pylibraft*.whl
```

### Running the python tests

```bash
# After pylibraft and libraft have been installed, from within the conda environment:
cd <HIPRAFT_ROOT>/python/pylibraft/
LD_LIBRARY_PATH=${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH} py.test -s -v
```

It should be noted that we append the `lib` path of the current `conda` environment. This is not always necessary; it depends on whether the `libraft` Python package already contains its own `libraft.so` and `librapids-logger.so`. If the `libraft` wheel was built in an environment where the `hipRAFT` CMake package was found, `libraft.so` is **not** bundled into the `libraft` Python module. In that case, the user must ensure that both `libraft.so` and `librapids-logger.so` are accessible to the system loader.

```bash
# From an environment without the hipRAFT CMake package installed
cd <HIPRAFT_ROOT>/python/libraft
pip wheel -w dist -v --no-deps --no-build-isolation --disable-pip-version-check .
```
The resulting wheel in the `dist` directory will also package libraft.so and other dependencies.

Inspecting the contents of `libraft-*-linux_x86_64.whl`:
```bash
cd <HIPRAFT_ROOT>/python/libraft/dist
unzip libraft*.whl
```
The directory structure will resemble the following:
```
libraft
|-- VERSION
|-- __init__.py
|-- _version.py
|-- include
|   |-- cuco
|   |-- raft
|   |-- raft_runtime
|   |-- rapids
|   |-- rapids_logger
|   `-- rmm
|-- lib
|   |-- cmake
|   |-- libraft.so
|   |-- librapids_logger.so
|   `-- rapids
`-- load.py
```
## Packaging with build.sh

The following command will generate a debian : `hipraft_<VERSION>_amd64.deb` in `<HIPRAFT_ROOT>/cpp/build`.

```bash
./build.sh libraft --compile-lib package
```

### Custom cpack generators

To generate other types of packages like `tar` or `rpm` packages:

```bash
# Configure
mkdir -p <HIPRAFT_ROOT>/cpp/build
rm -rf <HIPRAFT_ROOT>/cpp/build/*
cd <HIPRAFT_ROOT>/cpp/build
cmake -S .. \
      -G Ninja \
      -B . \
      -DCMAKE_INSTALL_PREFIX=install \
      -DCMAKE_HIP_ARCHITECTURES=NATIVE \
      -DCMAKE_BUILD_TYPE=Release \
      -DRAFT_COMPILE_LIBRARY=ON \
      -DBUILD_TESTS=OFF \
      -DCMAKE_CXX_COMPILER=hipcc

# Install to staging area
ninja install

# Invoke cpack to generate package
cpack -G RPM # To generate a RPM package. hipraft-25.02.00-Linux.rpm will be created at <HIPRAFT_ROOT>/cpp/build.
cpack -G TGZ # To generate a TGZ package. hipraft-25.02.00-Linux.tar.gz will be created at <HIPRAFT_ROOT>/cpp/build.
```

## Building the primitives benchmarks

The primitives benchmarks can be built using the `bench-prims` target in `build.sh`.

```bash
cd <HIPRAFT_ROOT>
./build.sh bench-prims --compile-lib  clean

```
This will build all the primitives benchmarks and place the resulting binaries in `cpp/build/bench/prims`.

```bash
ls -l <HIPRAFT_ROOT>/cpp/build/bench/prims/
  CMakeFiles
  cmake_install.cmake
  CORE_BENCH
  LINALG_BENCH
  MATRIX_BENCH
  RANDOM_BENCH
  SPARSE_BENCH
  UTIL_BENCH

```

## Building Documentation

Prepare the environment to build documentation using the following commands:

```bash
cd <HIPRAFT_ROOT>
# Activate the pylibraft conda environment.
micromamba activate pylibraft
# Install dependencies and tools required for generating documentation.
pip install -r docs/sphinx/requirements.txt
```

### Use `build.sh` to generate documentation

```bash
cd <HIPRAFT_ROOT>
./build.sh docs clean
```

Navigate to `<HIPRAFT_ROOT>/docs/_build` and use the tool of your choice, e.g. Firefox, to open and examine the root level html file, `index.html`. From this point you should be able to navigate through the documentation.

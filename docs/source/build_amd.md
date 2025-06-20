# Build and Installation

hipRAFT currently provides libraries for C++ and Python.

## Table of Contents

- [GPU Requirements](#tested-on-the-following-gpus)
- [Dependencies](#dependencies)
- [Docker](#docker)
- [Environment Variables](#environment-variables)
- [C++ library](#c-library)
  - [Header-only C++](#header-only-c)
  - [C++ Shared Library](#c-shared-library-optional)
  - [C++ Tests](#c-tests)
  - [`ccache` and `sccache`](#ccache-and-sccache)
  - [Using CMake directly](#using-cmake-directly)

- [Python library](#python-library)
  - [Conda environment scripts](#conda-environment-scripts)
  - [Building and installing](#building-and-installing-pylibraft)
  - [Running the python tests](#running-the-python-tests)
- [Packaging](#packaging)
------

### Tested on the following GPUs

| Accelerator         | Architecture | Wavefront Size | LLVM target |
|---------------------|--------------|----------------|-------------|
| AMD Instinct MI210  | CDNA2        | 64             | gfx90a      |
| AMD Instinct MI250  | CDNA2        | 64             | gfx90a      |
| AMD Instinct MI250X | CDNA2        | 64             | gfx90a      |
| AMD Instinct MI300A | CDNA3        | 64             | gfx942      |
| AMD Instinct MI300X | CDNA3        | 64             | gfx942      |

### Dependencies

> **Primary requirement**
> hipRAFT builds against the **AMD ROCm software stack**—that is, the ROCm runtime, HIP compiler tool-chain, and a GPU driver that matches your ROCm version.
> Install ROCm ≥ 6.4.0 (or the minimum version supported by the GPUs listed above) and make sure the `rocminfo` and `hipcc` commands are in your `PATH`.

| Name                                                             | Version / Notes                              |
| ----------------------------------------------------------       | -------------------------------------------- |
| [`cmake`](https://cmake.org/)                                    | ≥ 3.31.0                                     |
| [`ninja`](https://ninja-build.org/)                              | ≥ 1.11.1                                     |
| [`hipsolver`](https://github.com/ROCm/hipSOLVER)                 | Version that comes bundled with ROCm ≥ 6.4.0 |
| [`hipblas`](https://github.com/ROCm/hipblas)                     | Version that comes bundled with ROCm ≥ 6.4.0 |
| [`hipblaslt`](https://github.com/ROCm/hipBLASLt)                 | Version that comes bundled with ROCm ≥ 6.4.0 |
| [`hiprand`](https://github.com/ROCm/hiprand)                     | Version that comes bundled with ROCm ≥ 6.4.0 |
| [`hipsparse`](https://github.com/ROCm/hipSPARSE)                 | Version that comes bundled with ROCm ≥ 6.4.0 |
| [`libblas-dev`](https://www.netlib.org/lapack/)                  | Tested with 3.12.0                           |
| [`liblapack-dev`](https://www.netlib.org/lapack/)                | Tested with 3.12.0                           |
| **Additional Required Dependencies**                                 |                                          |
| **\***[`hipMM`](https://github.com/ROCm-DS/hipMM)                | Version must match hipRAFT                   |
| **\***[`hipCollections`](https://github.com/ROCm/hipCollections) | Version must match hipRAFT`                  |
| **\***[`hipCUB`](https://github.com/ROCm/hipCUB)                 | Version that comes bundled with ROCm ≥ 6.4.0 |
| **\***[`rocThrust`](https://github.com/ROCm/rocThrust)           | Version that comes bundled with ROCm ≥ 6.4.0 |
| **\*\***[`OpenMP`](https://www.openmp.org/)                        | Version that comes bundled with ROCm ≥ 6.4.0 |
| **Optional Dependencies**                                        |                                              |
| [`RCCL`](https://github.com/ROCm/rccl)                           | Version that comes bundled with ROCm ≥ 6.4.0 |
| [`UCX`](https://github.com/openucx/ucx)                          | ≥ 1.17.0                                     |
| [`Googletest`](https://github.com/google/googletest)             | ≥ 1.13.0                                     |
| [`Googlebench`](https://github.com/google/benchmark)             | ≥ 1.13.0                                     |
| [`Doxygen`](https://github.com/doxygen/doxygen)                  | >=1.8.20                                     |

**\*** Note: In the case of dependencies marked with an asterisk, if not found locally; the CMake build system will attempt to download a compatible version using
[ROCmDS-cmake](https://github.com/ROCm-DS/ROCmDS-cmake).

**\*\*** Note: The `OpenMP` toolchain is automatically installed as part of the standard ROCm installation and is available under /`opt/rocm-{version}/llvm`.

### Docker

For convenience hipRAFT also provides an [Ubuntu distribution-based Dockerfile](Dockerfile) that encapsulates all the above dependencies for development. Below are the instructions to create a container using this Dockerfile.

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
This container will have all necessary packages installed to build and run hipRAFT properly. This will create an Ubuntu 24.04 container that has ROCm installed. If you wish to use Ubuntu 22.04, replace the docker build command with the following:

```bash
docker build --build-arg UBUNTU=22.04 -t <RAFT_DEV_IMAGE> .
```
------


## Environment variables

```bash
export CMAKE_PREFIX_PATH=/opt/rocm/lib/cmake # Set CMAKE_PREFIX_PATH to point to the ROCm installation site
```

### Development environment variables
**The following environment variables are only required to be set for internal development. This section will be removed when hipRAFT becomes public.**


Set the Github personal access token(`GITHUB_PASS`). Note `GITHUB_PASS` should be configured to authorize access to the `AMD-AI` organization.
```bash
export GITHUB_PASS=<GITHUB_PERSONAL_ACCESS_TOKEN>
```

hipRAFT currently depends on custom branch of [`rocmds-logger`](https://github.com/AMD-AI/rocmds-logger) and as a result we need a custom branch of `ROCmDS-cmake` to pull this specific version of `rocmds-logger`. The following environment variables help select this specific version of `ROCmDS-cmake`:
```bash
export RAPIDS_CMAKE_BRANCH=feat/25.04-logger
export RAPIDS_CMAKE_URL=https://${GITHUB_PASS}@github.com/AMD-AI/ROCmDS-cmake
```

## C++ library

### Header-only C++

`build.sh` uses [ROCmDS-cmake](https://github.com/ROCm-DS/ROCmDS-cmake), which will automatically download any dependencies which are not already installed. It's important to note that while all the headers will be installed and available.

The following example will download the needed dependencies and install the hipRAFT headers into `$INSTALL_PREFIX/include/hipRAFT`.
```bash
./build.sh libraft
```
The `-n` flag can be passed to just have the build download the needed dependencies. Since hipRAFT's C++ headers are primarily used during build-time in downstream projects, the dependencies will never be installed by the hipRAFT build.
```bash
./build.sh libraft -n
```

Once installed, `libraft` headers (and dependencies which were downloaded and installed using `ROCmDS-cmake`) can be uninstalled also using `build.sh`:
```bash
./build.sh libraft --uninstall
```
### C++ Shared Library (optional)

A shared library must be built in order to build `pylibraft`. Pass the `--compile-lib` flag to `build.sh` to build the library:
```bash
./build.sh libraft --compile-lib
```

In above example the shared library is installed by default into `$INSTALL_PREFIX/lib`. To disable this, pass `-n` flag.

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

It can take sometime to compile all of the tests. You can build individual tests by providing a semicolon-separated list to the `--limit-tests` option in `build.sh`:

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

When building hipRAFT from source, the `build.sh` script offers a nice wrapper around the `cmake` commands to ease the burdens of manually configuring the various available cmake options. When more fine-grained control over the CMake configuration is desired, the `cmake` command can be invoked directly as the below example demonstrates.

The `CMAKE_INSTALL_PREFIX` installs hipRAFT into a specific location. The example below installs hipRAFT into the current Conda environment:
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
      -DCUDA_BACKEND=OFF \
      -DRAFT_COMPILE_LIBRARY=ON \
      -DBUILD_TESTS=ON \
      -DCMAKE_CXX_COMPILER=hipcc
# Build all targets
ninja
# Install
ninja install
```

hipRAFT's CMake has the following configurable flags available:

| Flag                      | Possible Values                     | Default Value | Behavior                                                                                                                                                            |
|---------------------------|-------------------------------------| --------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| CUDA_BACKEND              | ON, OFF                             | OFF           | Compile for the CUDA or HIP Backend                                                                                                                                 |
| CMAKE_HIP_ARCHITECTURES   | NATIVE or specific GPU architectures| NATIVE        | NATIVE to compile for the automatically detected GPU on the system. Can also specify `;` delimited list of specific architectures. Example: `gfx942;gfx1100` |
| BUILD_TESTS               | ON, OFF                             | ON            | Compile Googletests                                                                                                                                                 |
| DETECT_CONDA_ENV          | ON, OFF                             | ON            | Enable detection of conda environment for dependencies                                                                                                              |
| raft_FIND_COMPONENTS      | compiled distributed                |               | Configures the optional components as a space-separated list                                                                                                        |
| RAFT_COMPILE_LIBRARY      | ON, OFF                             | ON if either BUILD_TESTS or BUILD_PRIMS_BENCH is ON; otherwise OFF | Compiles all `libraft` shared libraries (these are required for Googletests)                                   |
| RAFT_COMPILE_DYNAMIC_ONLY | ON, OFF                             | OFF           | Only build the shared library and skip the static library. Has no effect if RAFT_COMPILE_LIBRARY is OFF                                                             |



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
pip wheel -w dist -v --no-deps --no-build-isolation --disable-pip-version-check .
# Install libraft wheel
pip install dist/libraft-*.whl

# Build pylibraft python wheel
cd <HIPRAFT_ROOT>/python/pylibraft/
pip wheel -w dist -v --no-deps --no-build-isolation --disable-pip-version-check .
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
## Packaging

### Packaging with build.sh

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
      -DCUDA_BACKEND=OFF \
      -DRAFT_COMPILE_LIBRARY=ON \
      -DBUILD_TESTS=OFF \
      -DCMAKE_CXX_COMPILER=hipcc

# Install to staging area
ninja install

# Invoke cpack to generate package
cpack -G RPM # To generate a RPM package. hipraft-25.02.00-Linux.rpm will be created at <HIPRAFT_ROOT>/cpp/build.
cpack -G TGZ # To generate a TGZ package. hipraft-25.02.00-Linux.tar.gz will be created at <HIPRAFT_ROOT>/cpp/build.
```

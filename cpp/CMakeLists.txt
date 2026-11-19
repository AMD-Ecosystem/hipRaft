# =============================================================================
# cmake-format: off
# SPDX-FileCopyrightText: Copyright (c) 2020-2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
# cmake-format: on

# cmake-format: off
# MIT License
#
# Modifications Copyright (C) 2024-2026 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# cmake-format: on

cmake_minimum_required(VERSION 3.30.4 FATAL_ERROR)

# NOTE(HIP/AMD): make *.cu files HIP lang files
set(CMAKE_USER_MAKE_RULES_OVERRIDE "${CMAKE_CURRENT_LIST_DIR}/../overrides.cmake")

include(../cmake/rapids_config.cmake)
include(rapids-cmake)
include(rapids-cpm)
include(rapids-export)
include(rapids-find)

# prescribe versions of internal dependencies
include(cpm/package_override)
# message(STATUS ${CMAKE_CURRENT_LIST_DIR})
rapids_cpm_package_override(${CMAKE_CURRENT_LIST_DIR}/../versions.json)

option(BUILD_CPU_ONLY "Build CPU only components. Applies to RAFT ANN benchmarks currently" OFF)
option(CUDA_BACKEND "Build for CUDA devices. Default configuration builds for AMD devices." OFF)

# workaround for rapids_cuda_init_architectures not working for arch detection with
# enable_language(CUDA)
set(lang_list "CXX")

if(NOT BUILD_CPU_ONLY)
  if(CUDA_BACKEND)
    include(rapids-cuda)
    rapids_cuda_init_architectures(RAFT)
    list(APPEND lang_list "CUDA")
  else()
    include(rapids-hip)
    rapids_hip_init_architectures(RAFT)
    list(APPEND lang_list "HIP")
  endif()
endif()

project(
  RAFT
  VERSION ${RAPIDS_VERSION}
  LANGUAGES ${lang_list}
)

# Disable C++20 module scanning (not using modules, just C++20 features)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

# Write the version header
rapids_cmake_write_version_file(include/raft/version_config.hpp)

# ##################################################################################################
# * build type ---------------------------------------------------------------

# Set a default build type if none was specified
rapids_cmake_build_type(Release)

# this is needed for clang-tidy runs
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ##################################################################################################
# * User Options  ------------------------------------------------------------

option(BUILD_SHARED_LIBS "Build raft shared libraries" ON)
option(BUILD_TESTS "Build raft unit-tests" ON)
option(BUILD_PRIMS_BENCH "Build raft C++ benchmark tests" OFF)
option(CUDA_ENABLE_KERNELINFO "Enable kernel resource usage info" OFF)
option(CUDA_ENABLE_LINEINFO
       "Enable the -lineinfo option for nvcc (useful for cuda-memcheck / profiler)" OFF
)
option(CUDA_STATIC_MATH_LIBRARIES "Statically link the CUDA math libraries" OFF)
option(CUDA_LOG_COMPILE_TIME "Write a log of compilation times to nvcc_compile_log.csv" OFF)
option(DETECT_CONDA_ENV "Enable detection of conda environment for dependencies" ON)
option(DISABLE_DEPRECATION_WARNINGS "Disable deprecaction warnings " ON)
option(DISABLE_OPENMP "Disable OpenMP" OFF)
option(RAFT_NVTX "Enable nvtx markers" OFF)

set(RAFT_COMPILE_LIBRARY_DEFAULT OFF)
if(BUILD_TESTS OR BUILD_PRIMS_BENCH)
  set(RAFT_COMPILE_LIBRARY_DEFAULT ON)
endif()
option(RAFT_COMPILE_LIBRARY "Enable building raft library instantiations"
       ${RAFT_COMPILE_LIBRARY_DEFAULT}
)
option(RAFT_COMPILE_DYNAMIC_ONLY "Only build the shared library and skip the
static library. Has no effect if RAFT_COMPILE_LIBRARY is OFF" OFF
)

option(ENABLE_CODE_COVERAGE "turn on flags for code coverage" OFF)

# Needed because GoogleBenchmark changes the state of FindThreads.cmake, causing subsequent runs to
# have different values for the `Threads::Threads` target. Setting this flag ensures
# `Threads::Threads` is the same value across all builds so that cache hits occur
set(THREADS_PREFER_PTHREAD_FLAG ON)

include(CMakeDependentOption)
# cmake_dependent_option( RAFT_USE_FAISS_STATIC "Build and statically link the FAISS library for
# nearest neighbors search on GPU" ON RAFT_COMPILE_LIBRARY OFF )

message(VERBOSE "RAFT: Building optional components: ${raft_FIND_COMPONENTS}")
message(VERBOSE "RAFT: Build RAFT unit-tests: ${BUILD_TESTS}")
message(VERBOSE "RAFT: Building raft C++ benchmarks: ${BUILD_PRIMS_BENCH}")
message(VERBOSE "RAFT: Enable detection of conda environment for dependencies: ${DETECT_CONDA_ENV}")
message(VERBOSE "RAFT: Disable depreaction warnings " ${DISABLE_DEPRECATION_WARNINGS})
message(VERBOSE "RAFT: Disable OpenMP: ${DISABLE_OPENMP}")
message(VERBOSE "RAFT: Enable kernel resource usage info: ${CUDA_ENABLE_KERNELINFO}")
message(VERBOSE "RAFT: Enable lineinfo in nvcc: ${CUDA_ENABLE_LINEINFO}")
message(VERBOSE "RAFT: Enable nvtx markers: ${RAFT_NVTX}")
message(VERBOSE "RAFT: Statically link the CUDA math libraries: ${CUDA_STATIC_MATH_LIBRARIES}")

# Set RMM logging level
set(RMM_LOGGING_LEVEL
    "INFO"
    CACHE STRING "Choose the logging level."
)
set_property(
  CACHE RMM_LOGGING_LEVEL PROPERTY STRINGS "TRACE" "DEBUG" "INFO" "WARN" "ERROR" "CRITICAL" "OFF"
)
message(VERBOSE "RAFT: RMM_LOGGING_LEVEL = '${RMM_LOGGING_LEVEL}'.")

# Set logging level
set(LIBRAFT_LOGGING_LEVEL
    "INFO"
    CACHE STRING "Choose the logging level."
)
set_property(
  CACHE LIBRAFT_LOGGING_LEVEL PROPERTY STRINGS "TRACE" "DEBUG" "INFO" "WARN" "ERROR" "CRITICAL"
                                       "OFF"
)
message(VERBOSE "RAFT: LIBRAFT_LOGGING_LEVEL = '${LIBRAFT_LOGGING_LEVEL}'.")

# ##################################################################################################
# * Conda environment detection ----------------------------------------------

if(DETECT_CONDA_ENV)
  rapids_cmake_support_conda_env(conda_env MODIFY_PREFIX_PATH)
  if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT AND DEFINED ENV{CONDA_PREFIX})
    message(
      STATUS "RAFT: No CMAKE_INSTALL_PREFIX argument detected, setting to: $ENV{CONDA_PREFIX}"
    )
    set(CMAKE_INSTALL_PREFIX "$ENV{CONDA_PREFIX}")
  endif()
endif()

# ##################################################################################################
# * compiler options ----------------------------------------------------------

set(_ctk_static_suffix "")
if(CUDA_STATIC_MATH_LIBRARIES)
  set(_ctk_static_suffix "_static")
endif()

if(CUDA_BACKEND)
  # CUDA runtime
  rapids_cuda_init_runtime(USE_STATIC ON)
  # * find CUDAToolkit package
  # * determine GPU architectures
  # * enable the CMake CUDA language
  # * set other CUDA compilation flags
  rapids_find_package(
    CUDAToolkit REQUIRED
    BUILD_EXPORT_SET raft-exports
    INSTALL_EXPORT_SET raft-exports
  )
else()
  # HIP runtime
  rapids_hip_init_runtime(USE_STATIC OFF)
  # * find HIP package
  # * determine GPU architectures
  # * enable the CMake CUDA language
  # * set other CUDA compilation flags
  rapids_find_package(
    HIP REQUIRED
    BUILD_EXPORT_SET raft-exports
    INSTALL_EXPORT_SET raft-exports
  )
endif()

if(NOT DISABLE_OPENMP)
  if(CUDA_BACKEND)
    # This is needed for the CUDA backend to find the OpenMP library. When using the HIP/ROCm
    # backend OpenMP is shipped as part of the ROCm LLVM toolchain. By passing -fopenmp the
    # toolchain will correctly add the required include paths and libraries. The install rpath will
    # also be set to find the OpenMP library. TODO: Clean this up when we get rid of the
    # CUDA_BACKEND option. This includes removing references to OpenMP related targets, variables
    # and flags from all the cmake files.
    rapids_find_package(
      OpenMP REQUIRED
      BUILD_EXPORT_SET raft-exports
      INSTALL_EXPORT_SET raft-exports
    )
    if(OPENMP_FOUND)
      message(VERBOSE "RAFT: OpenMP found in ${OpenMP_CXX_INCLUDE_DIRS}")
    endif()
  endif()
endif()

if(CUDA_BACKEND)
  include(cmake/modules/ConfigureCUDA.cmake)
else()
  include(cmake/modules/ConfigureHIP.cmake)
endif()

# ##################################################################################################
# * Requirements -------------------------------------------------------------

# add third party dependencies using CPM
rapids_cpm_init()

include(${rapids-cmake-dir}/cpm/rocmds_logger.cmake)
rapids_cpm_rapids_logger(BUILD_EXPORT_SET raft-exports INSTALL_EXPORT_SET raft-exports)
create_logger_macros(RAFT "raft::default_logger()" include/raft/core)

# CCCL before rmm so we get the right version of CCCL
include(cmake/thirdparty/get_cccl.cmake)

# rocprim, hipcub and rocthrust are imported via raw find_package() (not through rapids_cpm_find,
# which auto-promotes via rapids_cmake_make_global), so promote them to global scope here at the top
# level. This avoids partial export-set errors (e.g. roc::rocprim_hip defined but roc::rocprim not)
# when downstream packages re-process these targets from a different directory scope.
#
# Promote the COMPLETE export set of each package, not just the target raft links against:
# rocprim-targets.cmake exports {roc::rocprim, roc::rocprim_hip} and rocthrust-targets.cmake exports
# {roc::rocthrust, roc::hipstdpar}. If only one target from a set is global, a downstream
# find_package() (e.g. via rapids_cpm_cuco -> hipccl) sees a partial set and fails with "Some (but
# not all) targets in this export set were already defined."
set(_cccl_global_promote_targets
    roc::rocprim
    roc::rocprim_hip
    hip::hipcub
    roc::rocthrust
    roc::hipstdpar
    CCCL::CCCL
    CCCL::Thrust
    CCCL::CUB
    CCCL::libcudacxx
    libcudacxx::libcudacxx
    hipCCL::hipCCL
    hipCCL::hipcub
    hipCCL::rocThrust
    hipCCL::libhipcxx
)
include(${rapids-cmake-dir}/cmake/make_global.cmake)
rapids_cmake_make_global(_cccl_global_promote_targets)
unset(_cccl_global_promote_targets)

include(cmake/thirdparty/get_rmm.cmake)

if(BUILD_TESTS)
  include(${rapids-cmake-dir}/cpm/gtest.cmake)
  rapids_cpm_gtest(BUILD_STATIC)
  if(TARGET gtest)
    target_compile_options(gtest PRIVATE -w)
  endif()
endif()

if(BUILD_PRIMS_BENCH)
  include(${rapids-cmake-dir}/cpm/gbench.cmake)
  rapids_cpm_gbench(BUILD_STATIC)
  # Google Benchmark's __COUNTER__ usage triggers -Wc2y-extensions with HIP/clang
  foreach(_bench_tgt benchmark benchmark_main)
    if(TARGET ${_bench_tgt})
      target_compile_options(${_bench_tgt} PRIVATE -Wno-c2y-extensions)
    endif()
  endforeach()
endif()

# ##################################################################################################
# * code coverage ------------------------------------------------------------
if(ENABLE_CODE_COVERAGE AND PROJECT_IS_TOP_LEVEL)
  # ROCm clang also instruments device code: the new offload driver is needed to link the device
  # profile runtime, and the anchor gives TUs without device code the sections lld expects. CXX is
  # included because build.sh compiles CXX sources with hipcc. The profile list keeps device
  # functions that use __shared__ uninstrumented, see the file for why.
  find_package(Threads REQUIRED)
  add_compile_options(
    -fprofile-instr-generate
    -fcoverage-mapping
    "-fprofile-list=${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/coverage_profile_list.txt"
    "$<$<COMPILE_LANGUAGE:HIP,CXX>:--offload-new-driver;-include${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/coverage_anchor.h>"
  )
  add_link_options(-fprofile-instr-generate -fcoverage-mapping --offload-new-driver)
  link_libraries(Threads::Threads ${CMAKE_DL_LIBS})
endif()

# ##################################################################################################
# * raft ---------------------------------------------------------------------
add_library(raft INTERFACE)
add_library(raft::raft ALIAS raft)

target_include_directories(
  raft INTERFACE "$<BUILD_INTERFACE:${RAFT_SOURCE_DIR}/include>"
                 "$<BUILD_INTERFACE:${RAFT_BINARY_DIR}/include>" "$<INSTALL_INTERFACE:include>"
)

# Keep RAFT as lightweight as possible. Only CUDA libs and rmm should be used in global target.
target_link_libraries(raft INTERFACE rapids_logger::rapids_logger rmm::rmm CCCL::CCCL)

target_compile_features(raft INTERFACE cxx_std_17 $<BUILD_INTERFACE:cuda_std_17>)
target_compile_options(
  raft INTERFACE $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:--expt-extended-lambda
                 --expt-relaxed-constexpr> -DHIP_ENABLE_WARP_SYNC_BUILTINS
)
if(NOT DISABLE_OPENMP AND NOT CUDA_BACKEND)
  target_compile_options(raft INTERFACE -fopenmp)
  target_link_options(raft INTERFACE -fopenmp)
  # Note that by passing -fopenmp the compiler driver will already add the correct rpath for the
  # OpenMP implementation. However we also add a version-agnostic ROCm RPATH so we're not tied to a
  # specific ROCm version. This is only needed for the HIP/ROCm backend.
  target_link_options(raft INTERFACE "LINKER:-rpath,/opt/rocm/lib/llvm/lib")
endif()
target_compile_definitions(
  raft INTERFACE "RAFT_LOG_ACTIVE_LEVEL=RAPIDS_LOGGER_LOG_LEVEL_${LIBRAFT_LOGGING_LEVEL}"
)

if(CUDA_BACKEND)
  set(RAFT_CUSOLVER_DEPENDENCY CUDA::cusolver${_ctk_static_suffix})
  set(RAFT_CUBLAS_DEPENDENCY CUDA::cublas${_ctk_static_suffix})
  set(RAFT_CURAND_DEPENDENCY CUDA::curand${_ctk_static_suffix})
  set(RAFT_CUSPARSE_DEPENDENCY CUDA::cusparse${_ctk_static_suffix})
else()
  find_package(hipsolver CONFIG PATHS "/opt/rocm/")
  find_package(hipblas CONFIG PATHS "/opt/rocm/")
  find_package(hipblaslt CONFIG PATHS "/opt/rocm/")
  find_package(hiprand CONFIG PATHS "/opt/rocm/")
  find_package(hipsparse CONFIG PATHS "/opt/rocm/")
  find_package(rccl CONFIG PATHS "/opt/rocm/")
  find_package(MPI COMPONENTS CXX)
  rapids_find_package(ucx GLOBAL_TARGETS ucx::ucp ucx::ucs)
  if(TARGET ucx::ucs)
    include(../python/raft-dask/cmake/thirdparty/get_ucxx.cmake)
  endif()

  set(RAFT_CUSOLVER_DEPENDENCY hipsolver${_ctk_static_suffix})
  set(RAFT_CUBLAS_DEPENDENCY hipblas${_ctk_static_suffix})
  set(RAFT_CUBLASLT_DEPENDENCY hipblaslt${_ctk_static_suffix})
  set(RAFT_CURAND_DEPENDENCY hiprand${_ctk_static_suffix})
  set(RAFT_CUSPARSE_DEPENDENCY hipsparse${_ctk_static_suffix})
endif()

set(RAFT_CTK_MATH_DEPENDENCIES
    ${RAFT_CUBLAS_DEPENDENCY} ${RAFT_CUBLASLT_DEPENDENCY} ${RAFT_CUSOLVER_DEPENDENCY}
    ${RAFT_CUSPARSE_DEPENDENCY} ${RAFT_CURAND_DEPENDENCY}
)

# Endian detection
include(TestBigEndian)
test_big_endian(BIG_ENDIAN)
if(BIG_ENDIAN)
  target_compile_definitions(raft INTERFACE RAFT_SYSTEM_LITTLE_ENDIAN=0)
else()
  target_compile_definitions(raft INTERFACE RAFT_SYSTEM_LITTLE_ENDIAN=1)
endif()

if(RAFT_COMPILE_LIBRARY)
  # Enabling fatbin.ld for hip by replacing the calls with their hip equivalents results in static
  # initialization segfaults. If this becomes necessary, investigate enabling for HIP
  if(CUDA_BACKEND)
    file(
      WRITE "${CMAKE_CURRENT_BINARY_DIR}/fatbin.ld"
      [=[
SECTIONS
{
.nvFatBinSegment : { *(.nvFatBinSegment) }
.nv_fatbin : { *(.nv_fatbin) }
}
]=]
    )
  endif()
endif()

# ##################################################################################################
# * NVTX support in raft -----------------------------------------------------

if(RAFT_NVTX)
  # This enables NVTX within the project with no option to disable it downstream.
  if(CUDA_BACKEND)
    target_link_libraries(raft INTERFACE CUDA::nvtx3)
  else()
    target_link_libraries(raft INTERFACE roctx64)
  endif()
  target_compile_definitions(raft INTERFACE NVTX_ENABLED)
else()
  # Allow enable NVTX downstream if not set here. This creates a new option at build/install time,
  # which is set by default to OFF, but can be enabled in the dependent project.
  get_property(
    nvtx_option_help_string
    CACHE RAFT_NVTX
    PROPERTY HELPSTRING
  )
  string(
    CONCAT
      nvtx_export_string
      "option(RAFT_NVTX \""
      ${nvtx_option_help_string}
      "\" OFF)"
      [=[

target_link_libraries(raft::raft INTERFACE $<$<BOOL:${RAFT_NVTX}>:CUDA::nvtx3>)
target_compile_definitions(raft::raft INTERFACE $<$<BOOL:${RAFT_NVTX}>:NVTX_ENABLED>)

  ]=]
  )
endif()

# ##################################################################################################
# * raft_compiled ------------------------------------------------------------
add_library(raft_compiled INTERFACE)

if(TARGET raft_compiled AND (NOT TARGET raft::compiled))
  add_library(raft::compiled ALIAS raft_compiled)
endif()

set_target_properties(raft_compiled PROPERTIES EXPORT_NAME compiled)

if(RAFT_COMPILE_LIBRARY)
  add_library(
    raft_objs OBJECT
    src/raft_runtime/random/rmat_rectangular_generator_int64_double.cu
    src/raft_runtime/random/rmat_rectangular_generator_int64_float.cu
    src/raft_runtime/random/rmat_rectangular_generator_int_double.cu
    src/raft_runtime/random/rmat_rectangular_generator_int_float.cu
    src/raft_runtime/solver/lanczos_solver_int64_double.cu
    src/raft_runtime/solver/lanczos_solver_int64_float.cu
    src/raft_runtime/solver/lanczos_solver_int_double.cu
    src/raft_runtime/solver/lanczos_solver_int_float.cu
    src/raft_runtime/solver/randomized_svds_float.cu
    src/raft_runtime/solver/randomized_svds_double.cu
  )
  set_target_properties(
    raft_objs
    PROPERTIES CXX_STANDARD 20
               CXX_STANDARD_REQUIRED ON
               CUDA_STANDARD 20
               CUDA_STANDARD_REQUIRED ON
               POSITION_INDEPENDENT_CODE ON
  )
  set_target_properties(
    raft_objs
    PROPERTIES CXX_VISIBILITY_PRESET hidden
               CUDA_VISIBILITY_PRESET hidden
               VISIBILITY_INLINES_HIDDEN ON
  )

  target_compile_definitions(raft_objs PRIVATE "RAFT_EXPLICIT_INSTANTIATE_ONLY")
  target_compile_options(
    raft_objs PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:${RAFT_CXX_FLAGS}>"
                      "$<$<OR:$<COMPILE_LANGUAGE:CUDA>,$<COMPILE_LANGUAGE:HIP>>:${RAFT_GPU_FLAGS}>"
  )

  add_library(raft_lib SHARED $<TARGET_OBJECTS:raft_objs>)
  # (HIP/AMD): To work around: https://gitlab.kitware.com/cmake/cmake/-/issues/21787 and set the
  # right rpath to find libopenmp. Ideally linking against the OpenMP target should propagate the
  # link time flags but it does not.
  target_link_options(raft_lib PRIVATE $<$<BOOL:${OpenMP_FOUND}>:-fopenmp>)

  set(_raft_lib_targets raft_lib)
  if(NOT RAFT_COMPILE_DYNAMIC_ONLY)
    add_library(raft_lib_static STATIC $<TARGET_OBJECTS:raft_objs>)
    list(APPEND _raft_lib_targets raft_lib_static)
  endif()

  set_target_properties(
    ${_raft_lib_targets}
    PROPERTIES OUTPUT_NAME raft
               BUILD_RPATH "\$ORIGIN"
               INSTALL_RPATH "\$ORIGIN"
               INTERFACE_POSITION_INDEPENDENT_CODE ON
  )

  list(APPEND _raft_lib_targets raft_objs)
  foreach(target IN LISTS _raft_lib_targets)
    target_link_libraries(
      ${target}
      PUBLIC raft::raft
             ${RAFT_CTK_MATH_DEPENDENCIES} # TODO: Once `raft::resources` is used everywhere, this
                                           # will just be cublas
             $<TARGET_NAME_IF_EXISTS:OpenMP::OpenMP_CXX>
    )

    # So consumers know when using libraft.so/libraft.a
    target_compile_definitions(${target} PUBLIC "RAFT_COMPILED")
    # ensure CUDA symbols aren't relocated to the middle of the debug build binaries Renable the
    # next line if it becomes necessary target_link_options(${target} PRIVATE
    # "${CMAKE_CURRENT_BINARY_DIR}/fatbin.ld")
  endforeach()
endif()

if(TARGET raft_lib AND (NOT TARGET raft::raft_lib))
  add_library(raft::raft_lib ALIAS raft_lib)
endif()

target_link_libraries(raft_compiled INTERFACE raft::raft $<TARGET_NAME_IF_EXISTS:raft::raft_lib>)

# ##################################################################################################
# * raft_compiled_static----------------------------------------------------------------------------

if(NOT RAFT_COMPILE_DYNAMIC_ONLY)
  add_library(raft_compiled_static INTERFACE)

  if(TARGET raft_compiled_static AND (NOT TARGET raft::compiled_static))
    add_library(raft::compiled_static ALIAS raft_compiled_static)
  endif()
  set_target_properties(raft_compiled_static PROPERTIES EXPORT_NAME compiled_static)

  if(TARGET raft_lib_static AND (NOT TARGET raft::raft_lib_static))
    add_library(raft::raft_lib_static ALIAS raft_lib_static)
  endif()

  target_link_libraries(
    raft_compiled_static INTERFACE raft::raft $<TARGET_NAME_IF_EXISTS:raft::raft_lib_static>
  )
endif()

# ##################################################################################################
# * raft_distributed -------------------------------------------------------------------------------
#   NOTE(HIP/AMD): raft_distributed links ucxx::ucxx unconditionally. hip-ucxx is only
#   pinned/fetched during the raft-dask phase, so guard the whole target on the ucxx::ucxx target
#   being present. When absent (e.g. the standalone libraft C++ gate), raft_distributed and its ucxx
#   exports/installs are simply skipped; when present they build exactly as before.
if(TARGET ucxx::ucxx)
  add_library(raft_distributed INTERFACE)

  if(TARGET raft_distributed AND (NOT TARGET raft::distributed))
    add_library(raft::distributed ALIAS raft_distributed)
  endif()

  set_target_properties(raft_distributed PROPERTIES EXPORT_NAME distributed)

  if(CUDA_BACKEND)
    rapids_find_generate_module(
      NCCL
      HEADER_NAMES nccl.h
      LIBRARY_NAMES nccl
      BUILD_EXPORT_SET raft-distributed-exports
      INSTALL_EXPORT_SET raft-distributed-exports
    )
    rapids_export_package(BUILD NCCL raft-distributed-exports)
    rapids_export_package(INSTALL NCCL raft-distributed-exports)
  else()
    rapids_export_package(BUILD rccl raft-distributed-exports)
    rapids_export_package(INSTALL rccl raft-distributed-exports)
  endif()

  # NOTE(HIP/AMD): hip-ucxx exports ucxx::ucxx alone -- the amd-libhipucxx wheel has no python
  # component -- so requiring one would fail find_package(raft COMPONENTS distributed) downstream.
  rapids_export_package(BUILD ucxx raft-distributed-exports GLOBAL_TARGETS ucxx::ucxx)
  rapids_export_package(INSTALL ucxx raft-distributed-exports GLOBAL_TARGETS ucxx::ucxx)

  # ucx is a requirement for raft_distributed, but its config is not safe to be found multiple
  # times, so rather than exporting a package dependency on it above we rely on consumers to find it
  # themselves. Once https://github.com/rapidsai/ucxx/issues/173 is resolved we can export it above
  # again.
  target_link_libraries(
    raft_distributed INTERFACE ucx::ucs ucx::ucp ucxx::ucxx
                               $<IF:$<BOOL:${CUDA_BACKEND}>,NCCL::NCCL,roc::rccl>
  )
endif()

# ##################################################################################################
# * install targets-----------------------------------------------------------
rapids_cmake_install_lib_dir(lib_dir)
include(GNUInstallDirs)

install(
  TARGETS raft
  DESTINATION ${lib_dir}
  COMPONENT raft
  EXPORT raft-exports
)

set(_raft_compiled_install_targets raft_compiled)
if(NOT RAFT_COMPILE_DYNAMIC_ONLY)
  list(APPEND _raft_compiled_install_targets raft_compiled_static)
endif()
install(
  TARGETS ${_raft_compiled_install_targets}
  DESTINATION ${lib_dir}
  COMPONENT raft
  EXPORT raft-compiled-exports
)

if(TARGET raft_lib)
  install(
    TARGETS raft_lib
    DESTINATION ${lib_dir}
    COMPONENT compiled
    EXPORT raft-compiled-lib-exports
  )
  if(NOT RAFT_COMPILE_DYNAMIC_ONLY)
    install(
      TARGETS raft_lib_static
      DESTINATION ${lib_dir}
      COMPONENT compiled-static
      EXPORT raft-compiled-static-lib-exports
    )
  endif()
  install(
    DIRECTORY include/raft_runtime
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    COMPONENT compiled
  )
endif()

# NOTE(HIP/AMD): only install raft_distributed when it was actually created (ucxx::ucxx present).
if(TARGET raft_distributed)
  install(
    TARGETS raft_distributed
    DESTINATION ${lib_dir}
    COMPONENT distributed
    EXPORT raft-distributed-exports
  )
endif()

install(
  DIRECTORY include/raft
  COMPONENT raft
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/include/raft/version_config.hpp
  COMPONENT raft
  DESTINATION include/raft
)

# ##################################################################################################
# * install export -----------------------------------------------------------
set(doc_string
    [=[
Provide targets for the RAFT: Reusable Accelerated Functions and Tools

RAFT contains fundamental widely-used algorithms and primitives
for data science and machine learning.

Optional Components:
  - compiled
  - compiled_static
  - distributed

Imported Targets:
  - raft::raft
  - raft::compiled brought in by the `compiled` optional component
  - raft::compiled_static brought in by the `compiled_static` optional component
  - raft::distributed brought in by the `distributed` optional component

]=]
)

set(code_string ${nvtx_export_string})
if(CUDA_BACKEND)
  string(
    APPEND
    code_string
    [=[
if(compiled IN_LIST raft_FIND_COMPONENTS)
  enable_language(CUDA)
endif()
]=]
  )
else()
  string(
    APPEND
    code_string
    [=[
if(compiled IN_LIST raft_FIND_COMPONENTS)
  enable_language(HIP)
endif()
]=]
  )
endif()

set(raft_components compiled)
set(raft_export_sets raft-compiled-exports)
# NOTE(HIP/AMD): only export the `distributed` component when raft_distributed exists (ucxx::ucxx
# present). hip-ucxx is pinned at the raft-dask phase; the standalone C++ gate builds without it.
set(raft_distributed_global_target "")
if(TARGET raft_distributed)
  list(APPEND raft_components distributed)
  list(APPEND raft_export_sets raft-distributed-exports)
  set(raft_distributed_global_target distributed)
endif()
if(TARGET raft_lib)
  list(APPEND raft_components compiled)
  list(APPEND raft_export_sets raft-compiled-lib-exports)
  if(NOT RAFT_COMPILE_DYNAMIC_ONLY)
    list(APPEND raft_components compiled-static)
    list(APPEND raft_export_sets raft-compiled-static-lib-exports)
  endif()
endif()

string(
  APPEND
  code_string
  [=[
 option(RAFT_ENABLE_CUSOLVER_DEPENDENCY "Enable cusolver dependency" ON)
 option(RAFT_ENABLE_CUBLAS_DEPENDENCY "Enable cublas dependency" ON)
 option(RAFT_ENABLE_CURAND_DEPENDENCY "Enable curand dependency" ON)
 option(RAFT_ENABLE_CUSPARSE_DEPENDENCY "Enable cusparse dependency" ON)

mark_as_advanced(RAFT_ENABLE_CUSOLVER_DEPENDENCY)
mark_as_advanced(RAFT_ENABLE_CUBLAS_DEPENDENCY)
mark_as_advanced(RAFT_ENABLE_CURAND_DEPENDENCY)
mark_as_advanced(RAFT_ENABLE_CUSPARSE_DEPENDENCY)

target_link_libraries(raft::raft INTERFACE
  $<$<BOOL:${RAFT_ENABLE_CUSOLVER_DEPENDENCY}>:${RAFT_CUSOLVER_DEPENDENCY}>
  $<$<BOOL:${RAFT_ENABLE_CUBLAS_DEPENDENCY}>:${RAFT_CUBLAS_DEPENDENCY}>
  $<$<BOOL:${RAFT_ENABLE_CUSPARSE_DEPENDENCY}>:${RAFT_CUSPARSE_DEPENDENCY}>
  $<$<BOOL:${RAFT_ENABLE_CURAND_DEPENDENCY}>:${RAFT_CURAND_DEPENDENCY}>
  $<$<BOOL:${HIPDF_GPU_DEFINITIONS}>:${HIPDF_GPU_DEFINITIONS}>
)
]=]
)

# Use `rapids_export` for 22.04 as it will have COMPONENT support
rapids_export(
  INSTALL raft
  EXPORT_SET raft-exports
  COMPONENTS ${raft_components}
  COMPONENTS_EXPORT_SET ${raft_export_sets}
  GLOBAL_TARGETS raft compiled ${raft_distributed_global_target}
  NAMESPACE raft::
  DOCUMENTATION doc_string
  FINAL_CODE_BLOCK code_string
)

# ##################################################################################################
# * build export -------------------------------------------------------------
rapids_export(
  BUILD raft
  EXPORT_SET raft-exports
  COMPONENTS ${raft_components}
  COMPONENTS_EXPORT_SET ${raft_export_sets}
  GLOBAL_TARGETS raft compiled ${raft_distributed_global_target}
  DOCUMENTATION doc_string
  NAMESPACE raft::
  FINAL_CODE_BLOCK code_string
)

# ##################################################################################################
# * shared test/bench headers ------------------------------------------------

if(BUILD_TESTS OR BUILD_PRIMS_BENCH)
  add_subdirectory(internal)
endif()

# ##################################################################################################
# * build test executable ----------------------------------------------------

if(BUILD_TESTS)
  # include CTest module -- automatically calls enable_testing()
  include(CTest)
  add_subdirectory(tests)
endif()

# ##################################################################################################
# * build benchmark executable -----------------------------------------------

if(BUILD_PRIMS_BENCH)
  add_subdirectory(bench/prims/)
endif()

# ##################################################################################################
# * Packaging -----------------------------------------------------------------
set(CPACK_PACKAGE_NAME
    "hipraft"
    CACHE STRING "Overwrite package name."
)
set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_VENDOR "Advanced Micro Devices, Inc.")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_VENDOR}")
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_PACKAGING_INSTALL_PREFIX
    "/opt/rocm-ds"
    CACHE PATH "Package install prefix."
)
# System dependencies
set(CPACK_DEBIAN_PACKAGE_DEPENDS libsuitesparse-dev)
set(CPACK_RPM_PACKAGE_REQUIRES_LIST suitesparse-devel)
# Other ROCmDS packages
include("${rapids-cmake-dir}/cpm/detail/package_details.cmake")
macro(append_rocmds_package pkg_name deb_name rpm_name)
  # `rapids_cpm_package_details` was deprecated in 25.10 and removed in 26.02; calling it is a
  # FATAL_ERROR whenever the consuming project sets rapids-cmake-version >= 26.02 (e.g. the cuVS
  # wheel build, where libcuvs-python stamps 26.04 into scope before add_subdirectory'ing raft). Use
  # the internal helper, whose arg list adds a `subdir` slot after `tag`.
  rapids_cpm_package_details_internal(${pkg_name} version repository tag subdir shallow exclude)
  list(APPEND CPACK_DEBIAN_PACKAGE_DEPENDS "${deb_name} (= ${version})")
  list(APPEND CPACK_RPM_PACKAGE_REQUIRES_LIST "${rpm_name} = ${version}")
endmacro()
append_rocmds_package(hipmm hipmm hipmm)
append_rocmds_package(rocmds_logger rapids_logger rapids_logger)
append_rocmds_package(libhipcxx libhipcxx-dev libhipcxx-devel)
append_rocmds_package(hipco rocm-hipcollections-dev rocm-hipcollections-dev)

string(JOIN ", " CPACK_RPM_PACKAGE_REQUIRES ${CPACK_RPM_PACKAGE_REQUIRES_LIST})

include(CPack)

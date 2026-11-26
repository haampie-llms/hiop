#[[

Exports target `hiop_hip` which finds all hip libraries needed by hiop.

#]]

add_library(hiop_hip INTERFACE)
add_library(Hipblas INTERFACE)

# Get ROCm CMake Helpers onto your CMake Module Path
if (NOT DEFINED ROCM_PATH )
  if (NOT DEFINED ENV{ROCM_PATH} )
    set(ROCM_PATH "/opt/rocm" CACHE PATH "ROCm path")
  else()
    set(ROCM_PATH $ENV{ROCM_PATH} CACHE PATH "ROCm path")
  endif()
endif()
set(CMAKE_MODULE_PATH "${ROCM_PATH}/lib/cmake" ${CMAKE_MODULE_PATH})

# Set GPU Targets and Find all the HIP modules
set(GPU_TARGETS "gfx908" CACHE STRING "The GPU TARGETs")

# HIP sources are compiled with the HIP language, so the C++ compiler does not
# have to be a HIP compiler.
if(NOT DEFINED CMAKE_HIP_ARCHITECTURES)
  set(CMAKE_HIP_ARCHITECTURES "${GPU_TARGETS}" CACHE STRING "HIP architectures")
endif()
if(NOT DEFINED CMAKE_HIP_STANDARD)
  set(CMAKE_HIP_STANDARD ${CMAKE_CXX_STANDARD})
  set(CMAKE_HIP_STANDARD_REQUIRED ON)
endif()
enable_language(HIP)

find_package(hip REQUIRED)
find_package(hipfft REQUIRED)
find_package(hiprand REQUIRED)
find_package(rocrand REQUIRED)
message(STATUS "Found Hipblas include: ${HIPBLAS_INCLUDE_DIR}")
message(STATUS "Found Hipblas library: ${HIPBLAS_LIBRARY}")
find_package(hipblas REQUIRED)
find_package(rocblas REQUIRED)
message(STATUS "Found Hipblas include: ${HIPBLAS_INCLUDE_DIR}")
message(STATUS "Found Hipblas library: ${HIPBLAS_LIBRARY}")
find_package(hipcub REQUIRED)
find_package(rocprim REQUIRED)
find_package(rocthrust REQUIRED)

target_link_libraries(Hipblas INTERFACE ${HIPBLAS_LIBRARY})
target_include_directories(Hipblas INTERFACE ${HIPBLAS_INCLUDE_DIR})

# MAGMA is optional. Only discover and link it when explicitly enabled.
if(HIOP_USE_MAGMA)
  include(FindHiopMagma)
  if(NOT TARGET Magma)
    message(FATAL_ERROR
      "HIOP_USE_MAGMA is ON, but MAGMA was not found. Set MAGMA_DIR to "
      "the MAGMA installation prefix or configure with HIOP_USE_MAGMA=OFF.")
  endif()
  target_link_libraries(Magma INTERFACE Hipblas)
endif()

target_include_directories(hiop_hip INTERFACE ${ROCM_PATH}/include/hipfft)
# The HIP vector kernels use rocThrust
target_include_directories(hiop_hip INTERFACE $<BUILD_INTERFACE:${rocthrust_INCLUDE_DIRS}>)
target_link_libraries(hiop_hip INTERFACE
  hip::hiprand roc::rocrand
  hip::hipfft
  roc::hipblas roc::rocblas
  )

# hip::hipcub and roc::rocprim_hip link hip::device, which compiles every C++
# source as HIP and requires a HIP compiler as C++ compiler.
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  target_link_libraries(hiop_hip INTERFACE hip::hipcub roc::rocprim_hip)
endif()

if(HIOP_USE_MAGMA)
  target_link_libraries(hiop_hip INTERFACE Magma)
endif()

message(STATUS "HiOp support for GPUs is on")
get_target_property(hip_includes hiop_hip INTERFACE_INCLUDE_DIRECTORIES)
message(STATUS "HIP include directories: ${hip_includes}")
get_target_property(hip_libraries hiop_hip INTERFACE_LINK_LIBRARIES)
message(STATUS "HIP linked libraries: ${hip_libraries}")

install(TARGETS Hipblas hiop_hip EXPORT hiop-targets)

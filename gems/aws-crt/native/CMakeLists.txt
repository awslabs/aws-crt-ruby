cmake_minimum_required(VERSION 3.1)
project(aws-crt C)
message(STATUS "CMake ${CMAKE_VERSION}")

if (POLICY CMP0069)
    cmake_policy(SET CMP0069 NEW) # Enable LTO/IPO if available in the compiler
endif()

option(BIN_DIR "Location for built library" "")
if (BIN_DIR STREQUAL "")
    message(FATAL_ERROR "BIN_DIR must be set")
endif ()

if (DEFINED CMAKE_PREFIX_PATH)
    file(TO_CMAKE_PATH "${CMAKE_PREFIX_PATH}" CMAKE_PREFIX_PATH)
endif()

if (UNIX AND NOT APPLE)
    include(GNUInstallDirs)
elseif(NOT DEFINED CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR "lib")
endif()

if (${CMAKE_INSTALL_LIBDIR} STREQUAL "lib64")
    set(FIND_LIBRARY_USE_LIB64_PATHS true)
endif()

# This is required in order to append /lib/cmake to each element in CMAKE_PREFIX_PATH
set(AWS_MODULE_DIR "/${CMAKE_INSTALL_LIBDIR}/cmake")
string(REPLACE ";" "${AWS_MODULE_DIR};" AWS_MODULE_PATH "${CMAKE_PREFIX_PATH}${AWS_MODULE_DIR}")
# Append that generated list to the module search path
list(APPEND CMAKE_MODULE_PATH ${AWS_MODULE_PATH})

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/crt/aws-c-common/cmake")

include(AwsFindPackage)

set(IN_SOURCE_BUILD ON)

# Don't compile tests in subdirectories.
# Turn off using `option` instead of `set`, or CTest will declare
# it as an option later and override the existing variable.
option(BUILD_TESTING OFF)

add_subdirectory(crt/aws-c-common)

if (UNIX AND NOT APPLE)
    add_subdirectory(crt/aws-lc)
    add_subdirectory(crt/s2n)
endif()

add_subdirectory(crt/aws-c-io)
add_subdirectory(crt/aws-c-cal)
add_subdirectory(crt/aws-c-compression)
add_subdirectory(crt/aws-c-http)
add_subdirectory(crt/aws-c-auth)

include(AwsCFlags)
include(AwsSharedLibSetup)

file(GLOB AWS_CRT_SRC "src/*.h" "src/*.c")

add_library(${PROJECT_NAME} SHARED ${AWS_CRT_SRC})
# Add direct dependencies, they will add their transitives
aws_use_package(aws-c-http)
aws_use_package(aws-c-auth)

target_link_libraries(${PROJECT_NAME} PRIVATE ${DEP_AWS_LIBS})
aws_set_common_properties(${PROJECT_NAME})

# Build shared lib directly to BIN_DIR.
# for non-msvc, LIBRARY_OUTPUT_DIRECTORY controls the shared lib output
# for msvc, RUNTIME_OUTPUT_DIRECTORY controls where dlls are output
set_target_properties(${PROJECT_NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${BIN_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR}
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${BIN_DIR}
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${BIN_DIR}
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${BIN_DIR})

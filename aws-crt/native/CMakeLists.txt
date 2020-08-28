cmake_minimum_required(VERSION 3.1)
project(aws-crt C)

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

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/aws-common-runtime/aws-c-common/cmake")

include(AwsFindPackage)

set(IN_SOURCE_BUILD ON)
set(BUILD_TESTING OFF)

add_subdirectory(aws-common-runtime/aws-c-common)

if (UNIX AND NOT APPLE)
    add_subdirectory(aws-common-runtime/s2n)
endif()

add_subdirectory(aws-common-runtime/aws-c-io)
add_subdirectory(aws-common-runtime/aws-c-cal)
add_subdirectory(aws-common-runtime/aws-c-compression)
add_subdirectory(aws-common-runtime/aws-c-http)
add_subdirectory(aws-common-runtime/aws-c-auth)

include(AwsCFlags)
include(AwsSharedLibSetup)

file(GLOB AWS_CRT_SRC "src/*.h" "src/*.c")

add_library(${PROJECT_NAME} SHARED ${AWS_CRT_SRC})

aws_use_package(aws-c-common)
aws_use_package(aws-c-io)
aws_use_package(aws-c-cal)
aws_use_package(aws-c-compression)
aws_use_package(aws-c-http)
aws_use_package(aws-c-auth)

target_link_libraries(${PROJECT_NAME} PRIVATE ${DEP_AWS_LIBS})
aws_set_common_properties(${PROJECT_NAME})

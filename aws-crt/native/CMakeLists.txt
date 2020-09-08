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

file(GLOB AWS_CRT_SRC "src/*.h" "src/*.c")

add_library(${PROJECT_NAME} SHARED ${AWS_CRT_SRC})

include(AwsCFlags)
aws_set_common_properties(${PROJECT_NAME})

include(AwsFindPackage)
aws_use_package(aws-c-common)
if (UNIX AND NOT APPLE)
    aws_use_package(s2n)
endif()
aws_use_package(aws-c-io)
aws_use_package(aws-c-cal)
aws_use_package(aws-c-compression)
aws_use_package(aws-c-http)
aws_use_package(aws-c-auth)

target_link_libraries(${PROJECT_NAME} PRIVATE ${DEP_AWS_LIBS})

# Install as FILES so that lib goes exactly to install path.
# If installed as TARGETS, lib always goes under lib/ subfolder.
install(FILES $<TARGET_FILE:${PROJECT_NAME}> DESTINATION ${CMAKE_INSTALL_PREFIX})

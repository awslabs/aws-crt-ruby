cmake_minimum_required(VERSION 3.1)
project(aws-crt C)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/aws-common-runtime/aws-c-common/cmake")

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
install(FILES $<TARGET_FILE_NAME:${PROJECT_NAME}> DESTINATION ".")

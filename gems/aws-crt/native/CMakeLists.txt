cmake_minimum_required(VERSION 3.1)

option(BIN_DIR "Location for built library" "")
if (BIN_DIR STREQUAL "")
    message(FATAL_ERROR "BIN_DIR must be set")
endif ()

# Build shared lib directly to BIN_DIR.
# for non-msvc, LIBRARY_OUTPUT_DIRECTORY controls the shared lib output
# for msvc, RUNTIME_OUTPUT_DIRECTORY controls where dlls are output
set_target_properties(${PROJECT_NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${BIN_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR}
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${BIN_DIR}
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${BIN_DIR}
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${BIN_DIR})

add_subdirectory(crt/aws-crt-ffi)

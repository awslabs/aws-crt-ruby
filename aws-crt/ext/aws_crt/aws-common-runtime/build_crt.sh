#!/bin/sh

INSTALL_DIR="$(pwd)/build"

cmake -DCMAKE_PREFIX_PATH="$INSTALL_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -S aws-c-common -B aws-c-common/build
cmake --build aws-c-common/build --target install

cmake -DCMAKE_PREFIX_PATH="$INSTALL_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -S aws-c-io -B aws-c-io/build
cmake --build aws-c-io/build --target install

cmake -DCMAKE_PREFIX_PATH="$INSTALL_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -S aws-c-compression -B aws-c-compression/build
cmake --build aws-c-compression/build --target install

cmake -DCMAKE_PREFIX_PATH="$INSTALL_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -S aws-c-http -B aws-c-http/build
cmake --build aws-c-http/build --target install

cmake -DCMAKE_PREFIX_PATH="$INSTALL_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -S aws-c-cal -B aws-c-cal/build
cmake --build aws-c-cal/build --target install

cmake -DCMAKE_PREFIX_PATH="$INSTALL_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -S aws-c-auth -B aws-c-auth/build
cmake --build aws-c-auth/build --target install

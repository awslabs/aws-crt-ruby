/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

void aws_crt_init() {
  struct aws_allocator *allocator = aws_crt_allocator();
  aws_common_library_init(allocator);
  //TODO: Add these as needed?
//  aws_io_library_init(allocator);
//  aws_compression_library_init(allocator);
//  aws_http_library_init(allocator);
//  aws_cal_library_init(allocator);
//  aws_auth_library_init(allocator);
}

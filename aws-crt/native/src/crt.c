/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

struct aws_allocator *aws_crt_allocator(void) {
    return aws_default_allocator();
}

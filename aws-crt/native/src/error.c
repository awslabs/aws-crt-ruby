/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

#include <aws/common/error.h>

int aws_crt_test_error(void) {
  return aws_raise_error(AWS_ERROR_INVALID_STATE);
}

struct aws_crt_test_struct *aws_crt_test_pointer_error(void) {
    aws_raise_error(AWS_ERROR_OOM);
    return NULL;
}
/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

#include <aws/io/event_loop.h>

struct aws_crt_event_loop_group *aws_crt_event_loop_group_new(uint16_t max_threads) {
    struct aws_event_loop_group *elg =
        aws_event_loop_group_new_default(aws_crt_allocator(), max_threads, NULL /*shutdown_options*/);

    /* Don't need CRT-specific struct, so just cast */
    struct aws_crt_event_loop_group *crt_elg = (struct aws_crt_event_loop_group *)elg;
    return crt_elg;
}

void aws_crt_event_loop_group_release(struct aws_crt_event_loop_group *crt_elg) {
    /* Don't need CRT-specific struct, so just cast */
    struct aws_event_loop_group *elg = (struct aws_event_loop_group *)crt_elg;
    aws_event_loop_group_release(elg);
}

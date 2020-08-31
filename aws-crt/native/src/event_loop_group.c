/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

#include <aws/io/event_loop.h>

struct aws_crt_event_loop_group {
    struct aws_event_loop_group native;
};

struct aws_crt_event_loop_group *aws_crt_event_loop_group_new(uint16_t max_threads) {
    struct aws_crt_event_loop_group *crt_elg =
        aws_mem_calloc(aws_crt_allocator(), 1, sizeof(struct aws_crt_event_loop_group));
    if (!crt_elg) {
        goto error;
    }

    if (aws_event_loop_group_default_init(&crt_elg->native, aws_crt_allocator(), max_threads)) {
        goto error;
    }

    /* Success */
    return crt_elg;

error:
    aws_crt_event_loop_group_destroy(crt_elg);
    return NULL;
}

void aws_crt_event_loop_group_destroy(struct aws_crt_event_loop_group *crt_elg) {
    if (!crt_elg) {
        return;
    }

    aws_event_loop_group_clean_up(&crt_elg->native);
    aws_mem_release(aws_crt_allocator(), crt_elg);
}

/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

#include <aws/auth/credentials.h>
#include <aws/auth/signing_config.h>
#include <aws/common/string.h>

struct aws_crt_signing_config {
    struct aws_signing_config_aws native;
    struct aws_allocator *allocator;
    struct aws_atomic_var ref_count;
    struct aws_string *region_str;
    struct aws_string *service_str;
};

struct aws_crt_signing_config *aws_crt_signing_config_new(
    int algorithm,
    int signature_type,
    char *region,
    char *service,
    uint64_t date_epoch_ms,
    struct aws_credentials *credentials) {
    struct aws_allocator *allocator = aws_crt_allocator();
    struct aws_crt_signing_config *config = aws_mem_acquire(allocator, sizeof(struct aws_crt_signing_config));
    if (config == NULL) {
        return NULL;
    }
    config->allocator = allocator;
    aws_atomic_init_int(&config->ref_count, 1);

    AWS_ZERO_STRUCT(*config);
    // copy string data
    config->region_str = aws_string_new_from_c_str(allocator, region);
    config->service_str = aws_string_new_from_c_str(allocator, service);


    config->native.config_type = AWS_SIGNING_CONFIG_AWS;
    config->native.algorithm = algorithm;
    config->native.signature_type = signature_type;
    config->native.region = aws_byte_cursor_from_string(config->region_str);
    config->native.service = aws_byte_cursor_from_string(config->service_str);
    aws_date_time_init_epoch_millis(&config->native.date, date_epoch_ms); // TODO: should this be ms or sec?
    config->native.credentials = credentials;

    // TODO:
    // should_sign_header +  should_sign_header_ud (set to self?)
    // flags for: use_double_uri_encode, should_normalize_uri_path, ect

    if (aws_validate_aws_signing_config_aws(&config->native) != 0) {
        aws_crt_signing_config_release(config);
        return NULL;
    }

    return config;
}

void aws_crt_signing_config_release(struct aws_crt_signing_config *config) {
    if (config == NULL) {
        return;
    }

    size_t old_value = aws_atomic_fetch_sub(&config->ref_count, 1);
    if (old_value == 1) {
        if (config->region_str != NULL) {
            aws_string_destroy(config->region_str);
        }
        if (config->service_str != NULL) {
            aws_string_destroy(config->service_str);
        }
        aws_mem_release(config->allocator, config);
    }
}

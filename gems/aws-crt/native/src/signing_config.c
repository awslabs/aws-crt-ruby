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
    struct aws_string *region_str;
    struct aws_string *service_str;
    struct aws_string *signed_body_value_str;
};

struct aws_crt_signing_config *aws_crt_signing_config_new(
    int algorithm,
    int signature_type,
    const char *region,
    const char *service,
    const char *signed_body_value,
    uint64_t date_epoch_ms,
    struct aws_credentials *credentials,
    int aws_signed_body_header_type,
    aws_should_sign_header_fn *should_sign_header,
    bool use_double_uri_encode,
    bool should_normalize_uri_path,
    bool omit_session_token,
    uint64_t expiration_in_seconds) {
    struct aws_allocator *allocator = aws_crt_allocator();
    struct aws_crt_signing_config *config = aws_mem_acquire(allocator, sizeof(struct aws_crt_signing_config));

    AWS_ZERO_STRUCT(*config);
    // copy string data
    config->region_str = aws_string_new_from_c_str(allocator, region);
    config->service_str = aws_string_new_from_c_str(allocator, service);

    config->native.config_type = AWS_SIGNING_CONFIG_AWS;
    config->native.algorithm = algorithm;
    config->native.signature_type = signature_type;
    config->native.region = aws_byte_cursor_from_string(config->region_str);
    config->native.service = aws_byte_cursor_from_string(config->service_str);
    config->native.signed_body_header = aws_signed_body_header_type;

    if (signed_body_value != NULL) {
        config->signed_body_value_str = aws_string_new_from_c_str(allocator, signed_body_value);
        config->native.signed_body_value = aws_byte_cursor_from_string(config->signed_body_value_str);
    }

    aws_date_time_init_epoch_millis(&config->native.date, date_epoch_ms);
    aws_credentials_acquire(credentials);
    config->native.credentials = credentials;

    if (should_sign_header != NULL) {
        config->native.should_sign_header = should_sign_header;
    }

    config->native.flags.should_normalize_uri_path = should_normalize_uri_path;
    config->native.flags.use_double_uri_encode = use_double_uri_encode;
    config->native.flags.omit_session_token = omit_session_token;
    config->native.expiration_in_seconds = expiration_in_seconds;

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

    aws_string_destroy(config->region_str);
    aws_string_destroy(config->service_str);
    aws_string_destroy(config->signed_body_value_str);
    aws_credentials_release(config->native.credentials);

    aws_mem_release(aws_crt_allocator(), config);
}

bool aws_crt_signing_config_is_signing_synchronous(struct aws_crt_signing_config *config) {
    if (config == NULL) {
        return false;
    }
    return config->native.credentials_provider == NULL;
}

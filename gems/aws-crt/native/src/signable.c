/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

#include <aws/common/hash_table.h>
#include <aws/auth/signable.h>
#include <aws/common/string.h>

#define INITIAL_AWS_CRT_SIGNABLE_PROPERTIES_SIZE 10
#define INITIAL_AWS_CRT_SIGNABLE_PROPERTY_LISTS_TABLE_SIZE 10
#define INITIAL_AWS_CRT_SIGNABLE_PROPERTY_LIST_SIZE 10

struct aws_crt_signable_property {
    struct aws_string *name;
    struct aws_string *value;
};

struct aws_crt_signable_impl {
    struct aws_allocator *allocator;
    struct aws_hash_table properties;
    struct aws_hash_table property_lists;
};

static int s_aws_crt_signable_get_property(
    const struct aws_signable *signable,
    const struct aws_string *name,
    struct aws_byte_cursor *out_value) {

    struct aws_crt_signable_impl *impl = signable->impl;

    AWS_ZERO_STRUCT(*out_value);

    struct aws_hash_element *element = NULL;
    aws_hash_table_find(&impl->properties, name, &element);

    if (element != NULL) {
        *out_value = aws_byte_cursor_from_string(element->value);
        return AWS_OP_SUCCESS;
    }

    return aws_raise_error(AWS_ERROR_HASHTBL_ITEM_NOT_FOUND);
}

static int s_aws_crt_signable_get_property_list(
    const struct aws_signable *signable,
    const struct aws_string *name,
    struct aws_array_list **out_list) {

    (void)signable;
    (void)name;
    (void)out_list;

//    struct aws_crt_signable_impl *impl = signable->impl;
//
//    *out_list = NULL;
//
//    if (aws_string_eq(name, g_aws_http_headers_property_list_name)) {
//        *out_list = &impl->headers;
//    } else {
//        return AWS_OP_ERR;
//    }

    return AWS_OP_SUCCESS;
}

static int s_aws_crt_signable_get_payload_stream(
    const struct aws_signable *signable,
    struct aws_input_stream **out_input_stream) {

//    struct aws_crt_signable_impl *impl = signable->impl;
//    *out_input_stream = aws_http_message_get_body_stream(impl->request);
    (void)signable;
    (void)out_input_stream;

    return AWS_OP_SUCCESS;
}

static void s_aws_crt_signable_destroy(struct aws_signable *signable) {
    if (signable == NULL) {
        return;
    }

    struct aws_crt_signable_impl *impl = signable->impl;
    if (impl == NULL) {
        return;
    }

//    aws_array_list_clean_up(&impl->headers);
//    aws_mem_release(signable->allocator, signable);
}

static struct aws_signable_vtable s_aws_crt_signable_vtable = {
    .get_property = s_aws_crt_signable_get_property,
    .get_property_list = s_aws_crt_signable_get_property_list,
    .get_payload_stream = s_aws_crt_signable_get_payload_stream,
    .destroy = s_aws_crt_signable_destroy,
};

static void s_aws_crt_signable_property_clean_up(struct aws_crt_signable_property *pair) {
    aws_string_destroy(pair->name);
    aws_string_destroy(pair->value);
}

static void s_aws_hash_callback_property_list_destroy(void *value) {
    struct aws_array_list *property_list = value;

    size_t property_count = aws_array_list_length(property_list);
    for (size_t i = 0; i < property_count; ++i) {
        struct aws_crt_signable_property property;
        AWS_ZERO_STRUCT(property);

        if (aws_array_list_get_at(property_list, &property, i)) {
            continue;
        }

        s_aws_crt_signable_property_clean_up(&property);
    }

    struct aws_allocator *allocator = property_list->alloc;
    aws_array_list_clean_up(property_list);

    aws_mem_release(allocator, property_list);
}

struct aws_signable *aws_crt_signable_new(void) {
    struct aws_allocator *allocator = aws_crt_allocator();

    struct aws_signable *signable = NULL;
    struct aws_crt_signable_impl *impl = NULL;
    aws_mem_acquire_many(
        allocator, 2, &signable, sizeof(struct aws_signable), &impl, sizeof(struct aws_crt_signable_impl));

    if (signable == NULL || impl == NULL) {
        return NULL;
    }

    AWS_ZERO_STRUCT(*signable);
    AWS_ZERO_STRUCT(*impl);

    signable->allocator = allocator;
    signable->vtable = &s_aws_crt_signable_vtable;
    signable->impl = impl;

    impl->allocator = allocator;
    if (aws_hash_table_init(
            &impl->properties,
            allocator,
            INITIAL_AWS_CRT_SIGNABLE_PROPERTIES_SIZE,
            aws_hash_string,
            aws_hash_callback_string_eq,
            aws_hash_callback_string_destroy,
            aws_hash_callback_string_destroy) ||
        aws_hash_table_init(
            &impl->property_lists,
            allocator,
            INITIAL_AWS_CRT_SIGNABLE_PROPERTY_LISTS_TABLE_SIZE,
            aws_hash_string,
            aws_hash_callback_string_eq,
            aws_hash_callback_string_destroy,
            s_aws_hash_callback_property_list_destroy)) {
        goto on_error;
    }

    return signable;

    on_error:

        aws_signable_destroy(signable);

        return NULL;
}

int aws_crt_signable_set_property(
    struct aws_signable *signable,
    const char *property_name,
    const char *property_value) {

    if (signable == NULL) {
        return AWS_OP_ERR;
    }

    struct aws_crt_signable_impl *impl = signable->impl;
    if (impl == NULL) {
        return AWS_OP_ERR;
    }

    struct aws_string *name = NULL;
    struct aws_string *value = NULL;

    name = aws_string_new_from_c_str(impl->allocator, property_name);
    value = aws_string_new_from_c_str(impl->allocator, property_value);
    if (name == NULL || value == NULL) {
        goto on_error;
    }

    if (aws_hash_table_put(&impl->properties, name, value, NULL)) {
        goto on_error;
    }

    return AWS_OP_SUCCESS;

on_error:

    aws_string_destroy(name);
    aws_string_destroy(value);

    return AWS_OP_ERR;
}

const char *aws_crt_signable_get_property(struct aws_signable *signable, const char *property_name) {
    AWS_PRECONDITION(signable);
    struct aws_crt_signable_impl *impl = signable->impl;
    AWS_PRECONDITION(impl);

    struct aws_string *name = NULL;
    struct aws_byte_cursor out_value;

    name = aws_string_new_from_c_str(impl->allocator, property_name);
    if (name == NULL) {
        goto on_error;
    }

    int success = s_aws_crt_signable_get_property(signable, name, &out_value);
    if (success != 0) {
        goto on_error;
    }

    return (char*)out_value.ptr;

    on_error:

        aws_string_destroy(name);
        // TODO: Does out_value need to be cleaned up?
        return NULL;
}

void aws_crt_signable_release(struct aws_signable *signable) {
    aws_signable_destroy(signable);
}

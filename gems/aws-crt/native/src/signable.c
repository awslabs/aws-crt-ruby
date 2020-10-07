/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

#include <aws/auth/signable.h>
#include <aws/common/hash_table.h>
#include <aws/common/string.h>

#define INITIAL_AWS_CRT_SIGNABLE_PROPERTIES_SIZE 10
#define INITIAL_AWS_CRT_SIGNABLE_PROPERTY_LISTS_TABLE_SIZE 10
#define INITIAL_AWS_CRT_SIGNABLE_PROPERTY_LIST_SIZE 10

struct aws_crt_signable_impl {
    struct aws_allocator *allocator;
    struct aws_hash_table properties;
    struct aws_hash_table property_lists;
    struct aws_array_list str_buffer;
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

    struct aws_crt_signable_impl *impl = signable->impl;
    *out_list = NULL;

    struct aws_hash_element *element = NULL;
    aws_hash_table_find(&impl->property_lists, name, &element);

    if (element != NULL) {
        *out_list = element->value;
    }

    return AWS_OP_SUCCESS;
}

static int s_aws_crt_signable_get_payload_stream(
    const struct aws_signable *signable,
    struct aws_input_stream **out_input_stream) {

    // TODO: Need to implement bindings for input_stream
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

    aws_hash_table_clean_up(&impl->properties);
    aws_hash_table_clean_up(&impl->property_lists);

    if (aws_array_list_is_valid(&impl->str_buffer)) {
        const size_t string_count = aws_array_list_length(&impl->str_buffer);
        for (size_t i = 0; i < string_count; ++i) {
            struct aws_string *string = NULL;
            aws_array_list_get_at(&impl->str_buffer, &string, i);
            aws_string_destroy(string);
        }
        aws_array_list_clean_up(&impl->str_buffer);
    }

    aws_mem_release(signable->allocator, signable);
}

static struct aws_signable_vtable s_aws_crt_signable_vtable = {
    .get_property = s_aws_crt_signable_get_property,
    .get_property_list = s_aws_crt_signable_get_property_list,
    .get_payload_stream = s_aws_crt_signable_get_payload_stream,
    .destroy = s_aws_crt_signable_destroy,
};

static void s_aws_hash_callback_property_list_destroy(void *value) {
    struct aws_array_list *property_list = value;
    aws_array_list_clean_up(property_list);
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
            s_aws_hash_callback_property_list_destroy) ||
        aws_array_list_init_dynamic(
            &impl->str_buffer,
            allocator,
            INITIAL_AWS_CRT_SIGNABLE_PROPERTY_LIST_SIZE * 2,
            sizeof(struct aws_string *))) {
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

static struct aws_array_list *s_get_or_create_property_list(
    struct aws_signable *signable,
    const struct aws_string *list_name) {
    struct aws_crt_signable_impl *impl = signable->impl;
    struct aws_hash_element *element = NULL;

    aws_hash_table_find(&impl->property_lists, list_name, &element);

    if (element != NULL) {
        return element->value;
    }

    struct aws_array_list *properties = aws_mem_acquire(impl->allocator, sizeof(struct aws_array_list));
    if (properties == NULL) {
        return NULL;
    }

    AWS_ZERO_STRUCT(*properties);
    struct aws_string *name_copy = aws_string_new_from_string(impl->allocator, list_name);
    if (name_copy == NULL) {
        goto on_error;
    }

    if (aws_array_list_init_dynamic(
            properties,
            impl->allocator,
            INITIAL_AWS_CRT_SIGNABLE_PROPERTY_LIST_SIZE,
            sizeof(struct aws_signable_property_list_pair))) {
        goto on_error;
    }

    if (aws_hash_table_put(&impl->property_lists, name_copy, properties, NULL)) {
        goto on_error;
    }

    return properties;

on_error:

    aws_string_destroy(name_copy);
    aws_array_list_clean_up(properties);
    aws_mem_release(impl->allocator, properties);

    return NULL;
}

int aws_crt_signable_append_property_list(
    struct aws_signable *signable,
    const char *list_name,
    const char *property_name,
    const char *property_value) {

    if (signable == NULL) {
        return AWS_OP_ERR;
    }

    struct aws_crt_signable_impl *impl = signable->impl;
    if (impl == NULL) {
        return AWS_OP_ERR;
    }

    struct aws_string *list_name_str = NULL;
    struct aws_string *name = NULL;
    struct aws_string *value = NULL;

    list_name_str = aws_string_new_from_c_str(impl->allocator, list_name);

    struct aws_array_list *properties = s_get_or_create_property_list(signable, list_name_str);
    if (properties == NULL) {
        return AWS_OP_ERR;
    }

    name = aws_string_new_from_c_str(impl->allocator, property_name);
    value = aws_string_new_from_c_str(impl->allocator, property_value);
    if (name == NULL || value == NULL) {
        goto on_error;
    }

    struct aws_signable_property_list_pair property;
    property.name = aws_byte_cursor_from_string(name);
    property.value = aws_byte_cursor_from_string(value);

    if (aws_array_list_push_back(&impl->str_buffer, &name) || aws_array_list_push_back(&impl->str_buffer, &value)) {
        goto on_error;
    }

    if (aws_array_list_push_back(properties, &property)) {
        goto on_error;
    }

    aws_string_destroy(list_name_str);
    return AWS_OP_SUCCESS;

on_error:

    aws_string_destroy(list_name_str);
    aws_string_destroy(name);
    aws_string_destroy(value);

    return AWS_OP_ERR;
}

int aws_crt_signable_set_property_list(
    struct aws_signable *signable,
    const char *list_name,
    size_t count,
    const char **property_names,
    const char **property_values) {

    if (signable == NULL) {
        return AWS_OP_ERR;
    }

    struct aws_crt_signable_impl *impl = signable->impl;
    if (impl == NULL) {
        return AWS_OP_ERR;
    }

    struct aws_string *list_name_str = NULL;
    struct aws_string *name = NULL;
    struct aws_string *value = NULL;

    list_name_str = aws_string_new_from_c_str(impl->allocator, list_name);

    struct aws_array_list *properties = s_get_or_create_property_list(signable, list_name_str);
    if (properties == NULL) {
        goto on_error;
    }

    for (size_t i = 0; i < count; i++) {
        name = aws_string_new_from_c_str(impl->allocator, property_names[i]);
        value = aws_string_new_from_c_str(impl->allocator, property_values[i]);
        if (name == NULL || value == NULL) {
            goto on_error;
        }

        struct aws_signable_property_list_pair property;
        property.name = aws_byte_cursor_from_string(name);
        property.value = aws_byte_cursor_from_string(value);

        if (aws_array_list_push_back(&impl->str_buffer, &name) || aws_array_list_push_back(&impl->str_buffer, &value)) {
            goto on_error;
        }

        if (aws_array_list_push_back(properties, &property)) {
            goto on_error;
        }
    }

    aws_string_destroy(list_name_str);
    return AWS_OP_SUCCESS;

on_error:

    aws_string_destroy(list_name_str);
    aws_string_destroy(name);
    aws_string_destroy(value);

    return AWS_OP_ERR;
}

const char *aws_crt_signable_get_property(const struct aws_signable *signable, const char *property_name) {
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

    return (char *)out_value.ptr;

on_error:

    aws_string_destroy(name);
    return NULL;
}

void aws_crt_signable_release(struct aws_signable *signable) {
    aws_signable_destroy(signable);
}

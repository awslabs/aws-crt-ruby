#include "crt.h"

#include <aws/auth/signing_result.h>
#include <aws/common/string.h>

struct aws_crt_property_list {
    size_t len;
    const char **names;
    const char **values;
};

// Cannot error - return NULL for property not found
const char *aws_crt_signing_result_get_property(const struct aws_signing_result *result, const char *name) {
    if (result == NULL || name == NULL) {
        return NULL;
    }

    struct aws_string *out_property_value = NULL;
    struct aws_string *name_str = aws_string_new_from_c_str(result->allocator, name);

    aws_signing_result_get_property(result, name_str, &out_property_value);
    aws_string_destroy(name_str);

    if (out_property_value == NULL) {
        return NULL;
    }

    return aws_string_c_str(out_property_value);
}

// Cannot error - return NULL for property not found
struct aws_crt_property_list *aws_crt_signing_result_get_property_list(
    const struct aws_signing_result *result,
    const char *list_name) {
    if (result == NULL || list_name == NULL) {
        return NULL;
    }

    struct aws_array_list *result_param_list = NULL;
    struct aws_string *list_name_str = aws_string_new_from_c_str(result->allocator, list_name);

    aws_signing_result_get_property_list(result, list_name_str, &result_param_list);
    aws_string_destroy(list_name_str);

    if (result_param_list == NULL) {
        return NULL;
    }

    struct aws_crt_property_list *out = aws_mem_acquire(result->allocator, sizeof(struct aws_crt_property_list));
    AWS_ZERO_STRUCT(*out);

    if (aws_array_list_length(result_param_list) > 0) {
        size_t len = aws_array_list_length(result_param_list);
        out->len = len;
        out->names = aws_mem_acquire(result->allocator, len * sizeof(char *));
        out->values = aws_mem_acquire(result->allocator, len * sizeof(char *));

        for (size_t i = 0; i < len; i++) {
            struct aws_signing_result_property property;
            aws_array_list_get_at(result_param_list, &property, i);
            out->names[i] = aws_string_c_str(property.name);
            out->values[i] = aws_string_c_str(property.value);
        }
    }

    return out;
}

void aws_crt_property_list_release(struct aws_crt_property_list *property_list) {
    struct aws_allocator *allocator = aws_crt_allocator();
    if (property_list != NULL) {
        if (property_list->names != NULL) {
            aws_mem_release(allocator, (void *)property_list->names);
        }
        if (property_list->values != NULL) {
            aws_mem_release(allocator, (void *)property_list->values);
        }
        aws_mem_release(allocator, property_list);
    }
}

#ifndef AWS_CRT_API_H
#define AWS_CRT_API_H
/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

#include <aws/common/common.h>
#include <aws/auth/signing.h>

/* AWS_CRT_API marks a function as public */
#if defined(_WIN32)
#    define AWS_CRT_API __declspec(dllexport)
#else
#    if ((__GNUC__ >= 4) || defined(__clang__))
#        define AWS_CRT_API __attribute__((visibility("default")))
#    else
#        define AWS_CRT_API
#    endif
#endif

/* Forward declarations */
struct aws_event_loop_group;
struct aws_crt_test_struct;
struct aws_crt_property_list;

/* Public function definitions */
AWS_EXTERN_C_BEGIN

/* CRT */
AWS_CRT_API void aws_crt_init(void);
AWS_CRT_API int aws_crt_test_error(int);
AWS_CRT_API struct aws_crt_test_struct *aws_crt_test_pointer_error(void);
AWS_CRT_API int aws_crt_global_thread_creator_shutdown_wait_for(uint32_t wait_timeout_in_seconds);

/* Errors */
AWS_CRT_API int aws_crt_last_error(void);
AWS_CRT_API const char *aws_crt_error_str(int);
AWS_CRT_API const char *aws_crt_error_name(int);
AWS_CRT_API const char *aws_crt_error_debug_str(int);
AWS_CRT_API void aws_crt_reset_error(void);

/* IO */
AWS_CRT_API struct aws_event_loop_group *aws_crt_event_loop_group_new(uint16_t max_threads);
AWS_CRT_API void aws_crt_event_loop_group_release(struct aws_event_loop_group *elg);

/* Auth */
AWS_CRT_API struct aws_credentials *aws_crt_credentials_new(
    const char *access_key_id,
    const char *secret_access_key,
    const char *session_token,
    uint64_t expiration_timepoint_seconds);
AWS_CRT_API void aws_crt_credentials_release(struct aws_credentials *credentials);
AWS_CRT_API struct aws_byte_cursor aws_crt_credentials_get_access_key_id(const struct aws_credentials *credentials);
AWS_CRT_API struct aws_byte_cursor aws_crt_credentials_get_secret_access_key(const struct aws_credentials *credentials);
AWS_CRT_API struct aws_byte_cursor aws_crt_credentials_get_session_token(const struct aws_credentials *credentials);
AWS_CRT_API uint64_t aws_crt_credentials_get_expiration_timepoint_seconds(const struct aws_credentials *credentials);

AWS_CRT_API struct aws_crt_signing_config *aws_crt_signing_config_new(int algorithm, int signature_type, const char *region, const char *service, const char *signed_body_value, uint64_t date_epoch_ms, struct aws_credentials *credentials, int aws_signed_body_header_type);
AWS_CRT_API void aws_crt_signing_config_release(struct aws_crt_signing_config *config);

AWS_CRT_API struct aws_signable *aws_crt_signable_new(void);
AWS_CRT_API void aws_crt_signable_release(struct aws_signable *signable);
AWS_CRT_API int aws_crt_signable_set_property(struct aws_signable *signable, const char *property_name, const char *property_value);
AWS_CRT_API const char* aws_crt_signable_get_property(const struct aws_signable *signable, const char *property_name);
AWS_CRT_API int aws_crt_signable_append_property_list(struct aws_signable *signable, const char *list_name, const char *property_name, const char *property_value);
AWS_CRT_API int aws_crt_signable_set_property_list(struct aws_signable *signable, const char *list_name, size_t count, const char **property_names, const char **property_values);

AWS_CRT_API int aws_crt_sign_request(const struct aws_signable *signable, const struct aws_crt_signing_config *config, const char *sign_id, aws_signing_complete_fn *on_complete);

AWS_CRT_API const char *aws_crt_signing_result_get_property(const struct aws_signing_result *result, const char *name);
AWS_CRT_API struct aws_crt_property_list *aws_crt_signing_result_get_property_list(const struct aws_signing_result *result, const char *list_name);
AWS_CRT_API void aws_crt_property_list_release(struct aws_crt_property_list *property_list);

AWS_EXTERN_C_END

#endif /* AWS_CRT_API_H */

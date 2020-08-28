#ifndef AWS_CRT_API_H
#define AWS_CRT_API_H
/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

#include <aws/common/common.h>
#include <aws/io/io.h>
#include <aws/compression/compression.h>
#include <aws/http/http.h>
#include <aws/cal/cal.h>
#include <aws/auth/auth.h>

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
struct aws_crt_event_loop_group;
struct aws_crt_test_struct;

/* Public function definitions */
AWS_EXTERN_C_BEGIN

AWS_CRT_API void aws_crt_init(void);
AWS_CRT_API struct aws_crt_event_loop_group *aws_crt_event_loop_group_new(int max_threads);
AWS_CRT_API void aws_crt_event_loop_group_destroy(struct aws_crt_event_loop_group *crt_elg);
AWS_CRT_API int aws_crt_test_error(void);
AWS_CRT_API struct aws_crt_test_struct *aws_crt_test_pointer_error(void);

AWS_EXTERN_C_END

#endif /* AWS_CRT_API_H */

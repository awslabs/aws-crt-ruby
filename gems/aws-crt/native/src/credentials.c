/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
#include "crt.h"

#include <aws/common/string.h>
#include <aws/auth/credentials.h>

AWS_CRT_API struct aws_credentials *aws_crt_credentials_new(
  const char *access_key_id,
  const char *secret_access_key,
  const char *session_token,
  uint64_t expiration_timepoint_seconds) {

  struct aws_allocator *allocator = aws_crt_allocator();
  return aws_credentials_new_from_string(allocator,
    aws_string_new_from_c_str(allocator, access_key_id),
    aws_string_new_from_c_str(allocator, secret_access_key),
    session_token == NULL ? NULL : aws_string_new_from_c_str(allocator, session_token),
    expiration_timepoint_seconds);
    //TODO: Do these strings get cleaned up by the release of the credentials??
    //    aws_byte_cursor_from_c_str(access_key_id),
    //    aws_byte_cursor_from_c_str(secret_access_key),
    //    aws_byte_cursor_from_c_str(session_token),
}

const char *aws_crt_credentials_get_access_key_id(struct aws_credentials *credentials) {
  return (char *)aws_credentials_get_access_key_id(credentials).ptr;
}

const char *aws_crt_credentials_get_secret_access_key(struct aws_credentials *credentials) {
  return (char *)aws_credentials_get_secret_access_key(credentials).ptr;
}

const char *aws_crt_credentials_get_session_token(struct aws_credentials *credentials) {
  return (char *)aws_credentials_get_session_token(credentials).ptr;
}

uint64_t aws_crt_credentials_get_expiration_timepoint_seconds(struct aws_credentials *credentials) {
  return aws_credentials_get_expiration_timepoint_seconds(credentials);
}

void aws_crt_credentials_release(struct aws_credentials *credentials) {
    aws_credentials_release(credentials);
}

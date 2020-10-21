#include "crt.h"

#include <aws/auth/credentials.h>
#include <aws/auth/signing.h>
#include <aws/auth/signing_config.h>
#include <aws/common/string.h>

int aws_crt_sign_request(
    const struct aws_signable *signable,
    const struct aws_crt_signing_config *config,
    const char *sign_id,
    aws_signing_complete_fn *on_complete) {

    return aws_sign_request_aws(
        aws_crt_allocator(), signable, (struct aws_signing_config_base *)config, on_complete, (void *)sign_id);
}

int aws_crt_verify_sigv4a_signing(
    const struct aws_signable *signable,
    const struct aws_crt_signing_config *config,
    const char* expected_canonical_request,
    const char* signature,
    const char* ecc_key_pub_x,
    const char* ecc_key_pub_y) {

    return aws_verify_sigv4a_signing(
        aws_crt_allocator(), signable, (struct aws_signing_config_base *)config,
        aws_byte_cursor_from_c_str(expected_canonical_request),
        aws_byte_cursor_from_c_str(signature),
        aws_byte_cursor_from_c_str(ecc_key_pub_x),
        aws_byte_cursor_from_c_str(ecc_key_pub_y));
}

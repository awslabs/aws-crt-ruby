#include "crt.h"

#include <aws/auth/credentials.h>
#include <aws/auth/signing.h>
#include <aws/auth/signing_config.h>
#include <aws/common/string.h>

int aws_crt_sign_request(
    const struct aws_signable *signable,
    const struct aws_crt_signing_config *config,
    aws_signing_complete_fn *on_complete) {

    return aws_sign_request_aws(
        aws_crt_allocator(), signable, (struct aws_signing_config_base *)config, on_complete, NULL);
}

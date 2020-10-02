#include "crt.h"

#include <aws/auth/credentials.h>
#include <aws/auth/signing.h>
#include <aws/auth/signing_config.h>
#include <aws/common/string.h>

void aws_crt_signing_result_clean_up(struct aws_signing_result *result) {
    printf("Cleaning up signing result");
    aws_signing_result_clean_up(result);
}
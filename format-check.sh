#!/usr/bin/env bash

if [[ -z $CLANG_FORMAT ]] ; then
    CLANG_FORMAT=clang-format
fi

if NOT type $CLANG_FORMAT 2> /dev/null ; then
    echo "No appropriate clang-format found."
    exit 1
fi

FAIL=0
SOURCE_FILES=`find gems/aws-crt/native/src -type f \( -name '*.h' -o -name '*.c' \)`
for i in $SOURCE_FILES
do
    $CLANG_FORMAT -i $i
done

exit $FAIL

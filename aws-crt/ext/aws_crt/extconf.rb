require 'mkmf'

# Check for whatever we need to build our ext here
abort "missing malloc()" unless have_func "malloc"
abort "missing free()"   unless have_func "free"

# TODO: This currently does not work, even with common_dir specified fully
# find_header('device_random.h', common_dir)

create_header
create_makefile('aws_crt')

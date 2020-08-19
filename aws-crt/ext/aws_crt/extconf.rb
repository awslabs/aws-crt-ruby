require 'mkmf'

# Check for whatever we need to build our ext here
abort "missing malloc()" unless have_func "malloc"
abort "missing free()"   unless have_func "free"

create_makefile('aws_crt')

# extconf.rb is used as an install hook for pure ruby gems ONLY
# Create a blank makefile (Required)
# and then use cmake to build the CRT library and copy it to the
# expected location in the gem's bin directory
require 'mkmf'

abort 'Missing cmake' unless find_executable 'cmake'

# create a dummy makefile
create_makefile ''

# Build bin to expected location
require_relative 'compile'
crt_compile_bin

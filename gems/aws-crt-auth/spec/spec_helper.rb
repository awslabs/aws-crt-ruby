# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# use the local version of aws-crt
$LOAD_PATH.unshift File.expand_path('../../aws-crt/lib', __dir__)

puts $LOAD_PATH
require 'aws-crt-auth'

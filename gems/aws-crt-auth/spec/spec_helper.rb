# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../../aws-crt/lib', __dir__)

puts $LOAD_PATH
require 'aws-crt-auth'

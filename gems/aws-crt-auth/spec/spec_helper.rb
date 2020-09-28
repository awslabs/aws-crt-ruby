# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# use the local version of aws-crt
$LOAD_PATH.unshift File.expand_path('../../aws-crt/lib', __dir__)

require_relative '../../aws-crt/spec/spec_helper'
require 'aws-crt-auth'

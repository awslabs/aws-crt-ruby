# frozen_string_literal: true

require_relative 'aws-crt/platforms'
require_relative 'aws-crt/native'
require_relative 'aws-crt/errors'
require_relative 'aws-crt/managed_native'
require_relative 'aws-crt/io'

# Top level Amazon Web Services (AWS) namespace
module Aws
  # Top level namespace for all common runtime (CRT) functionality
  module Crt
    # Ensure native init() is called when gem loads
    Aws::Crt::Native.init
  end
end

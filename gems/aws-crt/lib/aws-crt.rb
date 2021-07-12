# frozen_string_literal: true

require_relative 'aws-crt/platforms'
require_relative 'aws-crt/native'
require_relative 'aws-crt/errors'
require_relative 'aws-crt/managed_native'
require_relative 'aws-crt/io'
require_relative 'aws-crt/string_blob'

# Top level Amazon Web Services (AWS) namespace
module Aws
  module Crt
    GEM_VERSION = File.read(File.expand_path('../VERSION', __dir__)).strip

    # Ensure native init() is called when gem loads
    Aws::Crt::Native.init
  end
end

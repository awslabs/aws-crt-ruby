# frozen_string_literal: true

require_relative 'aws-crt/platforms'
require_relative 'aws-crt/native'
require_relative 'aws-crt/errors'
require_relative 'aws-crt/managed_native'
require_relative 'aws-crt/string_blob'

require_relative 'aws-crt/io/event_loop_group'
require_relative 'aws-crt/http/headers'
require_relative 'aws-crt/http/message'

require_relative 'aws-crt/auth/credentials'
require_relative 'aws-crt/auth/static_credentials_provider'
require_relative 'aws-crt/auth/signing_config'
require_relative 'aws-crt/auth/signable'
require_relative 'aws-crt/auth/signer'
require_relative 'aws-crt/checksums/crc'

# Top level Amazon Web Services (AWS) namespace
module Aws
  # Common runtime bindings
  module Crt
    GEM_VERSION = File.read(File.expand_path('../VERSION', __dir__)).strip

    # Ensure native init() is called when gem loads
    Aws::Crt::Native.init
  end
end

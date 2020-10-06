# frozen_string_literal: true

require 'aws-crt'
require_relative 'aws-crt-auth/credentials'
require_relative 'aws-crt-auth/signing_config'
require_relative 'aws-crt-auth/signing_result'
require_relative 'aws-crt-auth/signable'
require_relative 'aws-crt-auth/signer'
require_relative 'aws-crt-auth/errors'

module Aws
  module Crt
    # High level Ruby abstractions for CRT Auth functionality
    module Auth
    end
  end
end

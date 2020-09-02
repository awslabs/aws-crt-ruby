# frozen_string_literal: true

require_relative 'aws-crt/platforms'
require_relative 'aws-crt/native'
require_relative 'aws-crt/errors'
require_relative 'aws-crt/io'

# Top level Amazon Web Services (AWS) namespace
module Aws
  # Top level namespace for all common runtime (CRT) functionality
  module Crt
    # Ensure native init() is called when gem loads
    Aws::Crt::Native.init

    # Invoke native call, and raise exception if it failed
    def self.call
      res = yield
      # functions that return void cannot fail
      return unless res

      # for functions that return int, non-zero indicates failure
      Errors.raise_last_error if res.is_a?(Integer) && res != 0

      # for functions that return pointer, NULL indicates failure
      Errors.raise_last_error if res == FFI::Pointer::NULL
      res
    end
  end
end

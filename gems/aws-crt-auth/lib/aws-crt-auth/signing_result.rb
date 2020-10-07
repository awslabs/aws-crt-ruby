# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Signing Config
      class SigningResult
        # Note: This is not needed as signing_result's memory is managed
        # by the sign_request callback lifecycle
        #
        # include Aws::Crt::ManagedNative
        # native_destroy Aws::Crt::Native.method(:signing_result_clean_up)

        # @param [FFI::Pointer] signing_result_ptr -
        #   FFI Pointer to a signing_result
        def initialize(signing_result_ptr)
          # manage_native { signing_result_ptr }
        end
      end
    end
  end
end

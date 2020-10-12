# frozen_string_literal: true

module Aws
  module Crt
    # High level Ruby abstractions for CRT Auth functionality
    module Auth
      # Ruby interface to CRT signing functions
      module Signer
        # Sign a request
        # @param [SigningConfig] - SigningConfig to apply to this signature
        # @param [Signable] - Signable object (request) to sign.
        #
        # @return [Hash] Return a hash with keys:
        #   * signature[String] - the computed signiture
        #   * headers[Hash] - signed headers, including the `Authorization`
        #      header.
        def self.sign_request(signing_config, signable)
          out = {}
          callback = proc do |result, status, _userdata|
            Aws::Crt::Errors.raise_last_error unless status.zero?
            out[:signature] = Aws::Crt::Native.signing_result_get_property(
              result, 'signature'
            )
            p_list = Aws::Crt::Native.signing_result_get_property_list(
              result, 'headers'
            )
            out[:headers] = p_list.props
            nil
          end

          # Currently this will always be synchronous
          # (because we are resolving credentials) - so do not need to
          # sync threads/callbacks
          Aws::Crt::Native.sign_request(
            signable.native, signing_config.native,
            signing_config.to_s, callback
          )
          out
        end
      end
    end
  end
end

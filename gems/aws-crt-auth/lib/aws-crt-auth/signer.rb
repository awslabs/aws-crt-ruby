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
          unless signing_config.signing_synchronous?
            raise ArgumentError, 'Signing will be asynchronous - this is not ' \
              'currently supported.  Please provide credentials directly ' \
              'when creating the SigningConfig.'
          end
          out = {}
          callback = proc do |result, status, _userdata|
            Aws::Crt::Errors.raise_last_error unless status.zero?
            out[:signature] = Aws::Crt::Native.signing_result_get_property(
              result, 'signature'
            )
            out[:headers] = Aws::Crt::Native.signing_result_get_property_list(
              result, 'headers'
            ).props

            out[:params] = Aws::Crt::Native.signing_result_get_property_list(
              result, 'params'
            ).props
            nil
          end

          # Currently this will always be synchronous
          # (because we are resolving credentials) - so do not need to
          # sync threads/callbacks
          Aws::Crt::Native.sign_request_synchronous(
            signable.native, signing_config.native, callback
          )
          out
        end
      end
    end
  end
end


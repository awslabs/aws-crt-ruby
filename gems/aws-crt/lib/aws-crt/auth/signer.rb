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
        #   * signature[String] - the computed signature
        #   * headers[Hash] - signed headers, including the `Authorization`
        #      header.
        def self.sign_request(signing_config, signable)
          out = {}
          callback = proc do |result, status, _userdata|
            Aws::Crt::Errors.raise_last_error unless status.zero?
            http_request = Http::Message.new('', '')
            Aws::Crt::Native.signing_result_apply_to_http_request(result,
                                                                  http_request.native)
            out[:headers] = http_request.headers
            if (auth = out[:headers]['Authorization']) &&
               (match = /Signature=([a-f0-9]+)/.match(auth))
              out[:signature] = match[1]
            end
            out[:http_request] = http_request

            nil
          end

          # Currently this will always be synchronous
          # (because we are resolving credentials) - so do not need to
          # sync threads/callbacks
          Aws::Crt::Native.sign_request_aws(
            signable.native, signing_config.native, callback, nil
          )
          out
        end
      end
    end
  end
end

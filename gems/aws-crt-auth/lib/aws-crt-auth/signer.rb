# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Utility class for creating AWS signature version 4 signature.
      class Signer
        def initialize(options = {})
          @service = extract_service(options)
          @region = extract_region(options)
          @credentials_provider = extract_credentials_provider(options)
          @unsigned_headers = Set.new((options.fetch(:unsigned_headers, []))
                                      .map(&:downcase))
          @unsigned_headers << 'authorization'
          @unsigned_headers << 'x-amzn-trace-id'
          @unsigned_headers << 'expect'
          %i[uri_escape_path apply_checksum_header].each do |opt|
            instance_variable_set("@#{opt}",
                                  options.key?(opt) ? options[:opt] : true)
          end
        end

        def sign_request(request)
          # TODO
        end

        def sign_event(prior_signature, payload, encoder)
          # TODO
        end

        def presign_url(options)
          # TODO
        end
      end
    end
  end
end

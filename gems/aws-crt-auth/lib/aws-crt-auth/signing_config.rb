# frozen_string_literal: true

require 'time'

module Aws
  module Crt
    module Auth
      # Signing Config
      class SigningConfig
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:signing_config_release)

        # @param [Hash] options
        # @option options [required, Aws::Crt::Native::signing_algorithm]
        #   :algorithm
        # @option options [required, Aws::Crt::Native::signature_type]
        #   :signature_type
        # @option options [required, Credentials] :credentials
        # @option options [required, String] :region
        # @option options [required, String] :service
        # @option options [Time] :date (Time.now)
        # @option options [Array<String>|Proc(ByteBuf->Boolean)]
        #   :unsigned_headers ([])
        # @option options [Boolean] :use_double_uri_encode (false)
        # @option options [Boolean] :should_normalize_uri_path (false)
        # @option options [Boolean] :omit_session_token (false)

        # @option options [Boolean] :apply_checksum_header (true)
        # @option options [String] :signed_body_value - Optional string to use
        #   as the canonical request's body value. If string is empty, a value
        #   will be calculated from the payload during signing. Typically,
        #   this is the SHA-256 of the (request/chunk/event) payload,
        #   written as lowercase hex. If this has been precalculated, it can
        #   be set here. Special values used by certain services can also
        #   be set (e.g. "UNSIGNED-PAYLOAD"
        #   "STREAMING-AWS4-HMAC-SHA256-PAYLOAD"
        #   "STREAMING-AWS4-HMAC-SHA256-EVENTS").
        def initialize(options = {})
          # validation of parameters is handled in signing_config_new

          # create a callback function for aws_should_sign_header_fn
          @sign_header_fn = extract_unsigned_header_fn(
            options[:unsigned_headers]
          )

          apply_checksum_header = extract_checksum_header(options)

          # ensure we retain a reference to the credentials to avoid GC
          @credentials = options[:credentials]
          manage_native do
            Aws::Crt::Native.signing_config_new(
              options[:algorithm],
              options[:signature_type],
              options[:region],
              options[:service],
              options[:signed_body_value],
              extract_date_ms(options),
              @credentials&.native,
              apply_checksum_header,
              @sign_header_fn,
              options.fetch(:use_double_uri_encode, false),
              options.fetch(:should_normalize_uri_path, false),
              options.fetch(:omit_session_token, false)
            )
          end
        end

        private

        def extract_checksum_header(options)
          if options.fetch(:apply_checksum_header, true)
            :sbht_content_sha256
          else
            :sbht_none
          end
        end

        def extract_date_ms(options)
          (options[:date] || Time.now).to_i * 1000
        end

        def extract_unsigned_header_fn(unsigned_headers)
          if unsigned_headers && !unsigned_headers.respond_to?(:call)
            unsigned_headers = Set.new(unsigned_headers.map(&:downcase))
            proc do |param, _p|
              !unsigned_headers.include? param.to_s.downcase
            end
          else
            unsigned_headers
          end
        end
      end
    end
  end
end

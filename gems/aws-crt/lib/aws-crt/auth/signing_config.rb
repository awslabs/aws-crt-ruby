# frozen_string_literal: true

require 'time'
require 'set'

module Aws
  module Crt
    module Auth
      # Signing Config
      class SigningConfig
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:signing_config_aws_release)

        # @param [Hash] options
        # @option options [required, Aws::Crt::Native::signing_algorithm]
        #   :algorithm
        # @option options [required, Aws::Crt::Native::signature_type]
        #   :signature_type
        # @option options [required, Credentials] :credentials
        # @option options [required, String] :region
        # @option options [required, String] :service
        # @option options [Time] :date (Time.now)
        # @option options [Array<String>]
        #   :unsigned_headers ([])
        # @option options [Boolean] :use_double_uri_encode (false)
        # @option options [Boolean] :should_normalize_uri_path (false)
        # @option options [Boolean] :omit_session_token (false)

        # @option options [Boolean] :signed_body_header_type
        #   (:sbht_content_sha256) -
        #   Controls if signing adds a header containing the
        #   canonical request's body value
        # @option options [String] :signed_body_value - Optional string to use
        #   as the canonical request's body value. If string is empty, a value
        #   will be calculated from the payload during signing. Typically,
        #   this is the SHA-256 of the (request/chunk/event) payload,
        #   written as lowercase hex. If this has been precalculated, it can
        #   be set here. Special values used by certain services can also
        #   be set (e.g. "UNSIGNED-PAYLOAD"
        #   "STREAMING-AWS4-HMAC-SHA256-PAYLOAD"
        #   "STREAMING-AWS4-HMAC-SHA256-EVENTS").
        # @option options[Integer] :expiration_in_seconds (0) -
        #   If non-zero and the
        #   signing transform is query param, then signing will add
        #   X-Amz-Expires to the query string, equal to the value
        #   specified here.  If this value is zero or if header signing
        #   is being used then this parameter has no effect.
        def initialize(options = {})
          # validation of parameters is handled in signing_config_new

          # create a callback function for aws_should_sign_header_fn
          @sign_header_fn = extract_unsigned_header_fn(
            options[:unsigned_headers]
          )

          signed_body_header_type = options.fetch(
            :signed_body_header_type,
            :sbht_content_sha256
          )

          # ensure we retain a reference to the credentials to avoid GC
          @credentials = options[:credentials]
          manage_native do
            Aws::Crt::Native.signing_config_aws_new
          end

          Aws::Crt::Native.signing_config_aws_set_algorithm(native, options[:algorithm])
          Aws::Crt::Native.signing_config_aws_set_signature_type(native, options[:signature_type])
          Aws::Crt::Native.signing_config_aws_set_region(native, options[:region], options[:region].length)
          Aws::Crt::Native.signing_config_aws_set_service(native, options[:service], options[:service].length)
          Aws::Crt::Native.signing_config_aws_set_date(native, extract_date(options))
          Aws::Crt::Native.signing_config_aws_set_credentials_provider(native, @credentials&.native)
          Aws::Crt::Native.signing_config_aws_set_signed_body_header_type(native, signed_body_header_type)
          if @sign_header_fn
            Aws::Crt::Native.signing_config_aws_set_should_sign_header_fn(native, @sign_header_fn)
          end

          assign_body_value(options)
          assign_flags(options)

          validate_config!
        end

        private

        def extract_date(options)
          (options[:date] || Time.now).to_i
        end

        def extract_unsigned_header_fn(unsigned_headers)
          return nil unless unsigned_headers&.size&.positive?

          unsigned_headers = Set.new(unsigned_headers.map(&:downcase))
          proc do |param_ptr, len, _p|
            param = param_ptr.read_string(len)
            !unsigned_headers.include? param.to_s.downcase
          end
        end

        def assign_flags(options)
          Aws::Crt::Native.signing_config_aws_set_use_double_uri_encode(native, options.fetch(:use_double_uri_encode, false))
          Aws::Crt::Native.signing_config_aws_set_should_normalize_uri_path(native, options.fetch(:should_normalize_uri_path, false))
          Aws::Crt::Native.signing_config_aws_set_omit_session_token(native, options.fetch(:omit_session_token, false))
          Aws::Crt::Native.signing_config_aws_set_expiration_in_seconds(native, options.fetch(:expiration_in_seconds, 0))
        end

        def assign_body_value(options)
          if options[:signed_body_value]
            Aws::Crt::Native.signing_config_aws_set_signed_body_value(native, options[:signed_body_value], options[:signed_body_value].length)
          end
        end

        def validate_config!
          unless Aws::Crt::Native.signing_config_aws_validate(native)
            # validate returns a boolean rather than int to indicate status
            # but still sets the exception
            Errors.raise_last_error
          end
        end
      end
    end
  end
end

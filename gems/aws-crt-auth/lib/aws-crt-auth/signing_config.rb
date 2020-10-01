# frozen_string_literal: true

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
        # @option options [Array<String>|Proc(String->Boolean)]
        #   :unsigned_headers ([])
        # @option options [Boolean] :uri_escape_path (true)
        # @option options [Boolean] :apply_checksum_header (true)
        def initialize(options = {})
          # validation of parameters is handled in signing_config_new

          # create a callback function for aws_should_sign_header_fn
          sign_header_fn = extract_unsigned_header_fn(
            options[:unsigned_headers]
          )
          puts "TODO: imp #{sign_header_fn}" if sign_header_fn

          # ensure we retain a reference to the credentials to avoid GC
          @credentials = options[:credentials]
          manage_native do
            Aws::Crt::Native.signing_config_new(
              options[:algorithm],
              options[:signature_type],
              options[:region],
              options[:service],
              extract_date(options),
              @credentials&.native
            )
          end
        end

        private

        def extract_date(options)
          (options[:date] || Time.now).to_i
        end

        def extract_unsigned_header_fn(unsigned_headers)
          if unsigned_headers && !unsigned_headers.respond_to?(:call)
            unsigned_headers = Set.new(unsigned_headers)
            sign_header_fn = proc { |param| unsigned_headers.include? param }
          end
          sign_header_fn
        end
      end
    end
  end
end

# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Signing Config
      # @api private
      class SigningConfig
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

          native = Aws::Crt.call do
            Aws::Crt::Native.signing_config_new(
              options[:algorithm],
              options[:signature_type],
              options[:region],
              options[:service],
              extract_date(options),
              options[:credentials]&.native
            )
          end

          @native = FFI::AutoPointer.new(native, self.class.method(:on_release))
        end

        # Immediately release this instance's attachment to the underlying
        # resources, without waiting for the garbage collector.
        # Note that underlying resources will remain alive until nothing
        # else is using them.
        def release
          return unless @native

          @native.free
          @native = nil
        end

        def self.on_release(native)
          Aws::Crt::Native.signing_config_release(native)
        end

        private

        def extract_date(options)
          (options[:date] || Time.now).to_i
        end

        def extract_unsigned_header_fn(unsigned_headers)
          if options[:unsigned_headers] &&
             !options[:unsigned_headers].respond_to?(:call)
            unsigned_headers = Set.new(options[:unsigned_headers])
            sign_header_fn = proc { |param| unsigned_headers.include? param }
          end
          sign_header_fn
        end
      end
    end
  end
end

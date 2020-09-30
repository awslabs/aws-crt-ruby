# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Signing Config
      # @api private
      class Signable
        # @param [Hash] options
        # @option options [required, Aws::Crt::Native::signing_algorithm]
        #   :algorithm
        def initialize(options = {})
          # validation of parameters is handled in signing_config_new

          # create a callback function for aws_should_sign_header_fn
          sign_header_fn = extract_unsigned_header_fn(
            options[:unsigned_headers]
          )
          puts "TODO: imp #{sign_header_fn}" if sign_header_fn

          # ensure we retain a reference to the credentials to avoid GC
          @credentials = options[:credentials]
          native = Aws::Crt.call do
            Aws::Crt::Native.signing_config_new(
              options[:algorithm],
              options[:signature_type],
              options[:region],
              options[:service],
              extract_date(options),
              @credentials&.native
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

      end
    end
  end
end

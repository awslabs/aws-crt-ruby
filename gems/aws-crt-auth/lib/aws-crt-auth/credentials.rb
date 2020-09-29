# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Utility class for Credentials.
      # @api private
      class Credentials
        UINT64_MAX = 18_446_744_073_709_551_615

        # @param [String] access_key_id
        # @param [String] secret_access_key
        # @param [String] session_token (nil)
        # @param [Time|int] expiration (nil)
        def initialize(access_key_id, secret_access_key,
                       session_token = nil, expiration = nil)
          if !access_key_id || access_key_id.empty?
            raise ArgumentError, 'access_key_id  must be set'
          end

          if !secret_access_key || secret_access_key.empty?
            raise ArgumentError, 'secret_access_key  must be set'
          end

          native = Aws::Crt.call do
            Aws::Crt::Native.credentials_new(
              access_key_id,
              secret_access_key,
              session_token,
              expiration&.to_i || UINT64_MAX
            )
          end

          @native = FFI::AutoPointer.new(native, self.class.method(:on_release))
        end

        # @return [FFI:Pointer]
        attr_reader :native

        # @return [String, nil]
        def access_key_id
          Aws::Crt::Native.credentials_get_access_key_id(@native) if @native
        end

        # @return [String, nil]
        def secret_access_key
          Aws::Crt::Native.credentials_get_secret_access_key(@native) if @native
        end

        # @return [String, nil]
        def session_token
          Aws::Crt::Native.credentials_get_session_token(@native) if @native
        end

        # @return [Time,nil]
        def expiration
          return unless @native

          exp = Aws::Crt::Native.credentials_get_expiration(@native)
          return if exp == UINT64_MAX

          Time.at(exp)
        end

        # @return [Credentials]
        def credentials
          self
        end

        # @return [Boolean] Returns `true` if the access key id and secret
        #   access key are both set.
        def set?
          !@native.nil? &&
            !access_key_id.nil? &&
            !access_key_id.empty? &&
            !secret_access_key.nil? &&
            !secret_access_key.empty?
        end

        # Removing the secret access key from the default inspect string.
        # @api private
        def inspect
          "#<#{self.class.name} access_key_id=#{access_key_id.inspect}>"
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
          Aws::Crt::Native.credentials_release(native)
        end
      end
    end
  end
end

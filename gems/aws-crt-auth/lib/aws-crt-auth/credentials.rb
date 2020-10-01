# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Utility class for Credentials.
      class Credentials
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:credentials_release)

        UINT64_MAX = 18_446_744_073_709_551_615

        # @param [String] access_key_id
        # @param [String] secret_access_key
        # @param [String] session_token (nil)
        # @param [Time|int] expiration (nil) - Either a Time or an int
        #   seconds since unix epoch
        def initialize(access_key_id, secret_access_key,
                       session_token = nil, expiration = nil)
          if !access_key_id || access_key_id.empty?
            raise ArgumentError, 'access_key_id  must be set'
          end

          if !secret_access_key || secret_access_key.empty?
            raise ArgumentError, 'secret_access_key  must be set'
          end

          manage_native do
            Aws::Crt::Native.credentials_new(
              access_key_id,
              secret_access_key,
              session_token,
              expiration&.to_i || UINT64_MAX
            )
          end
        end

        # @return [String]
        def access_key_id
          Aws::Crt::Native.credentials_get_access_key_id(native).to_s
        end

        # @return [String]
        def secret_access_key
          Aws::Crt::Native.credentials_get_secret_access_key(native).to_s
        end

        # @return [String, nil]
        def session_token
          Aws::Crt::Native.credentials_get_session_token(native).to_s
        end

        # @return [Time,nil]
        def expiration
          exp = Aws::Crt::Native.credentials_get_expiration_timepoint_seconds!(
            native
          )
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
          native_set?
        end

        # Removing the secret access key from the default inspect string.
        # @api private
        def inspect
          "#<#{self.class.name} access_key_id=#{access_key_id.inspect}>"
        end
      end
    end
  end
end

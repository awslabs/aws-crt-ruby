# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # CRT CredentialOptions
      class CredentialsOptions
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:credentials_options_release)

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
            Aws::Crt::Native.credentials_options_new
          end

          Aws::Crt::Native.credentials_options_set_access_key_id(
            native, access_key_id, access_key_id.length
          )

          Aws::Crt::Native.credentials_options_set_secret_access_key(
            native, secret_access_key, secret_access_key.length
          )

          if session_token && !session_token.empty?
            Aws::Crt::Native.credentials_options_set_session_token(
              native, session_token, session_token.length
            )
          end

          Aws::Crt::Native.credentials_options_set_expiration_timepoint_seconds(
            native, expiration&.to_i || UINT64_MAX
          )
        end
      end

      # Utility class for Credentials.
      class Credentials
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:credentials_release)

        # @param [String] access_key_id
        # @param [String] secret_access_key
        # @param [String] session_token (nil)
        # @param [Time|int] expiration (nil) - Either a Time or an int
        #   seconds since unix epoch
        def initialize(access_key_id, secret_access_key,
                       session_token = nil, expiration = nil)
          credential_options = CredentialsOptions.new(
            access_key_id, secret_access_key,
            session_token, expiration
          )
          manage_native do
            Aws::Crt::Native.credentials_new(
              credential_options.native
            )
          end
        end
      end
    end
  end
end

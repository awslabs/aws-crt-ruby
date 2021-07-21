# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # CRT CredentialOptions
      class StaticCredentialsProviderOptions
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:credentials_provider_static_options_release)

        # @param [String] access_key_id
        # @param [String] secret_access_key
        # @param [String] session_token (nil)
        def initialize(access_key_id, secret_access_key,
                       session_token = nil)
          if !access_key_id || access_key_id.empty?
            raise ArgumentError, 'access_key_id  must be set'
          end

          if !secret_access_key || secret_access_key.empty?
            raise ArgumentError, 'secret_access_key  must be set'
          end

          manage_native do
            Aws::Crt::Native.credentials_provider_static_options_new
          end

          Aws::Crt::Native.credentials_provider_static_options_set_access_key_id(
            native, access_key_id, access_key_id.length
          )

          Aws::Crt::Native.credentials_provider_static_options_set_secret_access_key(
            native, secret_access_key, secret_access_key.length
          )

          if session_token && !session_token.empty?
            Aws::Crt::Native.credentials_provider_static_options_set_session_token(
              native, session_token, session_token.length
            )
          end
        end
      end

      # Utility class for Credentials.
      class StaticCredentialsProvider
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:credentials_provider_release)

        # @param [String] access_key_id
        # @param [String] secret_access_key
        # @param [String] session_token (nil)
        def initialize(access_key_id, secret_access_key,
                       session_token = nil)

          credential_options = StaticCredentialsProviderOptions.new(
            access_key_id, secret_access_key,
            session_token
          )
          manage_native do
            Aws::Crt::Native.credentials_provider_static_new(
              credential_options.native
            )
          end
        end
      end
    end
  end
end

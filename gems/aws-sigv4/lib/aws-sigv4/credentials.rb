# frozen_string_literal: true

module Aws
  module Sigv4
    # Users that wish to configure static credentials can use the
    # `:access_key_id` and `:secret_access_key` constructor options.
    # @api private
    class StaticCredentialsProvider

      # @option options [Credentials] :credentials
      # @option options [String] :access_key_id
      # @option options [String] :secret_access_key
      # @option options [String] :session_token (nil)
      def initialize(options = {})
        @credentials =
          options[:credentials] || Aws::Crt::Auth::Credentials.new(
            options[:access_key_id],
            options[:secret_access_key],
            options[:session_token]
          )
      end

      # @return [Credentials]
      attr_reader :credentials

      # @return [Boolean]
      def set?
        !!credentials && credentials.set?
      end
    end

  end
end

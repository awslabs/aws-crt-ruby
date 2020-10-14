# frozen_string_literal: true

require 'openssl'
require 'time'
require 'tempfile'
require 'uri'
require 'set'

module Aws
  module Sigv4
    # Utility class for creating AWS signature version 4 signature.
    class Signer
      # @overload initialize(service:, region:, access_key_id:, secret_access_key:, session_token:nil, **options)
      #   @param [String] :service The service signing name, e.g. 's3'.
      #   @param [String] :region The region name, e.g. 'us-east-1'.
      #   @param [String] :access_key_id
      #   @param [String] :secret_access_key
      #   @param [String] :session_token (nil)
      #
      # @overload initialize(service:, region:, credentials:, **options)
      #   @param [String] :service The service signing name, e.g. 's3'.
      #   @param [String] :region The region name, e.g. 'us-east-1'.
      #   @param [Credentials] :credentials Any object that responds to the following
      #     methods:
      #
      #     * `#access_key_id` => String
      #     * `#secret_access_key` => String
      #     * `#session_token` => String, nil
      #     * `#set?` => Boolean
      #
      # @overload initialize(service:, region:, credentials_provider:, **options)
      #   @param [String] :service The service signing name, e.g. 's3'.
      #   @param [String] :region The region name, e.g. 'us-east-1'.
      #   @param [#credentials] :credentials_provider An object that responds
      #     to `#credentials`, returning an object that responds to the following
      #     methods:
      #
      #     * `#access_key_id` => String
      #     * `#secret_access_key` => String
      #     * `#session_token` => String, nil
      #     * `#set?` => Boolean
      #
      # @option options [Array<String>] :unsigned_headers ([]) A list of
      #   headers that should not be signed. This is useful when a proxy
      #   modifies headers, such as 'User-Agent', invalidating a signature.
      #
      # @option options [Boolean] :uri_escape_path (true) When `true`,
      #   the request URI path is uri-escaped as part of computing the canonical
      #   request string. This is required for every service, except Amazon S3,
      #   as of late 2016.
      #
      # @option options [Boolean] :apply_checksum_header (true) When `true`,
      #   the computed content checksum is returned in the hash of signature
      #   headers. This is required for AWS Glacier, and optional for
      #   every other AWS service as of late 2016.
      #
      def initialize(options = {})
        @service = extract_service(options)
        @region = extract_region(options)
        @credentials_provider = extract_credentials_provider(options)
        @unsigned_headers = Set.new((options.fetch(:unsigned_headers, []))
                                    .map(&:downcase))
        @unsigned_headers << 'authorization'
        @unsigned_headers << 'x-amzn-trace-id'
        @unsigned_headers << 'expect'
        @uri_escape_path = options.fetch(:uri_escape_path, true)
        @apply_checksum_header = options.fetch(:apply_checksum_header, true)
      end

      # @return [String]
      attr_reader :service

      # @return [String]
      attr_reader :region

      # @return [#credentials] Returns an object that responds to
      #   `#credentials`, returning an object that responds to the following
      #   methods:
      #
      #   * `#access_key_id` => String
      #   * `#secret_access_key` => String
      #   * `#session_token` => String, nil
      #   * `#set?` => Boolean
      #
      attr_reader :credentials_provider

      # @return [Set<String>] Returns a set of header names that should not be signed.
      #   All header names have been downcased.
      attr_reader :unsigned_headers

      # @return [Boolean] When `true` the `x-amz-content-sha256` header will be signed and
      #   returned in the signature headers.
      attr_reader :apply_checksum_header

      # Computes a version 4 signature signature. Returns the resultant
      # signature as a hash of headers to apply to your HTTP request. The given
      # request is not modified.
      #
      #     signature = signer.sign_request(
      #       http_method: 'PUT',
      #       url: 'https://domain.com',
      #       headers: {
      #         'Abc' => 'xyz',
      #       },
      #       body: 'body' # String or IO object
      #     )
      #
      #     # Apply the following hash of headers to your HTTP request
      #     signature.headers['host']
      #     signature.headers['x-amz-date']
      #     signature.headers['x-amz-security-token']
      #     signature.headers['x-amz-content-sha256']
      #     signature.headers['authorization']
      #
      # In addition to computing the signature headers, the canonicalized
      # request, string to sign and content sha256 checksum are also available.
      # These values are useful for debugging signature errors returned by AWS.
      #
      #     signature.canonical_request #=> "..."
      #     signature.string_to_sign #=> "..."
      #     signature.content_sha256 #=> "..."
      #
      # @param [Hash] request
      #
      # @option request [required, String] :http_method One of
      #   'GET', 'HEAD', 'PUT', 'POST', 'PATCH', or 'DELETE'
      #
      # @option request [required, String, URI::HTTPS, URI::HTTP] :url
      #   The request URI. Must be a valid HTTP or HTTPS URI.
      #
      # @option request [optional, Hash] :headers ({}) A hash of headers
      #   to sign. If the 'X-Amz-Content-Sha256' header is set, the `:body`
      #   is optional and will not be read.
      #
      # @option request [optional, String, IO] :body ('') The HTTP request body.
      #   A sha256 checksum is computed of the body unless the
      #   'X-Amz-Content-Sha256' header is set.
      #
      # @return [Signature] Return an instance of {Signature} that has
      #   a `#headers` method. The headers must be applied to your request.
      #
      def sign_request(request)
        creds = fetch_credentials

        http_method = extract_http_method(request)
        url = extract_url(request)
        headers = downcase_headers(request[:headers])

        datetime =
          if headers.include? 'x-amz-date'
            Time.parse(headers.delete('x-amz-date'))
          end

        content_sha256 = headers.delete('x-amz-content-sha256')
        content_sha256 ||= sha256_hexdigest(request[:body] || '')

        sigv4_headers = {}
        sigv4_headers['host'] = headers['host'] || host(url)
        if creds.session_token
          sigv4_headers['x-amz-security-token'] = creds.session_token
        end

        headers = headers.merge(sigv4_headers) # merge so we do not modify given headers hash

        config = Aws::Crt::Auth::SigningConfig.new(
          algorithm: :v4,
          signature_type: :http_request_headers,
          region: @region,
          service: @service,
          date: datetime,
          signed_body_value: content_sha256,
          signed_body_header_type: @apply_checksum_header ?
            :sbht_content_sha256 : :sbht_none,
          credentials: creds,
          unsigned_headers: @unsigned_headers,
          use_double_uri_encode: @uri_escape_path
        )
        signable = Aws::Crt::Auth::Signable.new(
          properties: { 'uri' => url.to_s, 'method' => http_method },
          property_lists: { 'headers' => headers }
        )

        signing_result = Aws::Crt::Auth::Signer.sign_request(config, signable)

        Signature.new(
          headers: sigv4_headers.merge(
            downcase_headers(signing_result[:headers])
          ),
          string_to_sign: 'CRT_INTERNAL',
          canonical_request: 'CRT_INTERNAL',
          content_sha256: content_sha256
        )
      end

      def sign_event(prior_signature, payload, encoder)
        # TODO
      end

      def presign_url(options)
        # TODO
      end

      private

      def extract_service(options)
        if options[:service]
          options[:service]
        else
          msg = 'missing required option :service'
          raise ArgumentError, msg
        end
      end

      def extract_region(options)
        options[:region] || raise(ArgumentError, 'Missing '\
          'required option :region')
      end

      def extract_credentials_provider(options)
        if options[:credentials_provider]
          options[:credentials_provider]
        elsif options.key?(:credentials) || options.key?(:access_key_id)
          StaticCredentialsProvider.new(options)
        else
          raise ArgumentError, 'Missing credentials'
        end
      end

      def fetch_credentials
        credentials = @credentials_provider.credentials
        if credentials&.native_set?
          credentials
        else
          raise Errors::MissingCredentialsError,
                'unable to sign request without credentials set'
        end
      end

      def extract_http_method(request)
        if request[:http_method]
          request[:http_method].upcase
        else
          msg = 'missing required option :http_method'
          raise ArgumentError, msg
        end
      end

      def extract_url(request)
        if request[:url]
          URI.parse(request[:url].to_s)
        else
          msg = 'missing required option :url'
          raise ArgumentError, msg
        end
      end

      def downcase_headers(headers)
        (headers || {}).to_hash.transform_keys(&:downcase)
      end

      # @param [File, Tempfile, IO#read, String] value
      # @return [String<SHA256 Hexdigest>]
      def sha256_hexdigest(value)
        if (value.is_a?(File) || value.is_a?(Tempfile)) && !value.path.nil? && File.exist?(value.path)
          OpenSSL::Digest::SHA256.file(value).hexdigest
        elsif value.respond_to?(:read)
          sha256 = OpenSSL::Digest.new('SHA256')
          loop do
            chunk = value.read(1024 * 1024) # 1MB
            break unless chunk

            sha256.update(chunk)
          end
          value.rewind
          sha256.hexdigest
        else
          OpenSSL::Digest::SHA256.hexdigest(value)
        end
      end

      def host(uri)
        # Handles known and unknown URI schemes; default_port nil when unknown.
        if uri.default_port == uri.port
          uri.host
        else
          "#{uri.host}:#{uri.port}"
        end
      end

      class << self

        # @api private
        def uri_escape_path(path)
          path.gsub(/[^\/]+/) { |part| uri_escape(part) }
        end

        # @api private
        def uri_escape(string)
          if string.nil?
            nil
          else
            CGI.escape(string.encode('UTF-8')).gsub('+', '%20').gsub('%7E', '~')
          end
        end
      end
    end

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

    Signature = Struct.new(
      :headers, :canonical_request,
      :string_to_sign, :content_sha256, keyword_init: true
    )
  end
end

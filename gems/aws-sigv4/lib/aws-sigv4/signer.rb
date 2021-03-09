# frozen_string_literal: true

require 'openssl'
require 'time'
require 'tempfile'
require 'uri'
require 'set'
require 'aws-eventstream'

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
      # @option options [Boolean] :omit_session_token (false) If `true`,
      #   then security token is added to the final signing result,
      #   but is treated as "unsigned" and does not contribute
      #   to the authorization signature.
      #
      # @option options [Boolean] :normalize_path (true) When `true`,
      #   the uri paths will be normalized when building the canonical request
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
        @signing_algorithm = options.fetch(:signing_algorithm, :sigv4)
        @normalize_path = options.fetch(:normalize_path, true)
        @omit_session_token = options.fetch(:omit_session_token, false)
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


        # Modify the user-agent to add usage of crt-signer
        # This should be temporary during developer preview only
        if headers.include? 'user-agent'
          headers['user-agent'] = "#{headers['user-agent']} crt-signer/#{Aws::Sigv4::VERSION}"
          sigv4_headers['user-agent'] = headers['user-agent']
        end

        headers = headers.merge(sigv4_headers) # merge so we do not modify given headers hash

        config = Aws::Crt::Auth::SigningConfig.new(
          algorithm: @signing_algorithm,
          signature_type: :http_request_headers,
          region: @region,
          service: @service,
          date: datetime,
          signed_body_value: content_sha256,
          signed_body_header_type: @apply_checksum_header ?
            :sbht_content_sha256 : :sbht_none,
          credentials: creds,
          unsigned_headers: @unsigned_headers,
          use_double_uri_encode: @uri_escape_path,
          should_normalize_uri_path: @normalize_path,
          omit_session_token: @omit_session_token
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
          content_sha256: content_sha256,
          extra: {config: config, signable: signable}
        )
      end

      # Signs a URL with query authentication. Using query parameters
      # to authenticate requests is useful when you want to express a
      # request entirely in a URL. This method is also referred as
      # presigning a URL.
      #
      # See [Authenticating Requests: Using Query Parameters (AWS Signature Version 4)](http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html) for more information.
      #
      # To generate a presigned URL, you must provide a HTTP URI and
      # the http method.
      #
      #     url = signer.presign_url(
      #       http_method: 'GET',
      #       url: 'https://my-bucket.s3-us-east-1.amazonaws.com/key',
      #       expires_in: 60
      #     )
      #
      # By default, signatures are valid for 15 minutes. You can specify
      # the number of seconds for the URL to expire in.
      #
      #     url = signer.presign_url(
      #       http_method: 'GET',
      #       url: 'https://my-bucket.s3-us-east-1.amazonaws.com/key',
      #       expires_in: 3600 # one hour
      #     )
      #
      # You can provide a hash of headers that you plan to send with the
      # request. Every 'X-Amz-*' header you plan to send with the request
      # **must** be provided, or the signature is invalid. Other headers
      # are optional, but should be provided for security reasons.
      #
      #     url = signer.presign_url(
      #       http_method: 'PUT',
      #       url: 'https://my-bucket.s3-us-east-1.amazonaws.com/key',
      #       headers: {
      #         'X-Amz-Meta-Custom' => 'metadata'
      #       }
      #     )
      #
      # @option options [required, String] :http_method The HTTP request method,
      #   e.g. 'GET', 'HEAD', 'PUT', 'POST', 'PATCH', or 'DELETE'.
      #
      # @option options [required, String, HTTPS::URI, HTTP::URI] :url
      #   The URI to sign.
      #
      # @option options [Hash] :headers ({}) Headers that should
      #   be signed and sent along with the request. All x-amz-*
      #   headers must be present during signing. Other
      #   headers are optional.
      #
      # @option options [Integer<Seconds>] :expires_in (900)
      #   How long the presigned URL should be valid for. Defaults
      #   to 15 minutes (900 seconds).
      #
      # @option options [optional, String, IO] :body
      #   If the `:body` is set, then a SHA256 hexdigest will be computed of the body.
      #   If `:body_digest` is set, this option is ignored. If neither are set, then
      #   the `:body_digest` will be computed of the empty string.
      #
      # @option options [optional, String] :body_digest
      #   The SHA256 hexdigest of the request body. If you wish to send the presigned
      #   request without signing the body, you can pass 'UNSIGNED-PAYLOAD' as the
      #   `:body_digest` in place of passing `:body`.
      #
      # @option options [Time] :time (Time.now) Time of the signature.
      #   You should only set this value for testing.
      #
      # @return [HTTPS::URI, HTTP::URI]
      #
      def presign_url(options)
        creds = fetch_credentials

        http_method = extract_http_method(options)
        url = extract_url(options)
        headers = downcase_headers(options[:headers])
        headers['host'] ||= host(url)

        datetime = headers.delete('x-amz-date')
        datetime ||= (options[:time] || Time.now)

        content_sha256 = headers.delete('x-amz-content-sha256')
        content_sha256 ||= options[:body_digest]
        content_sha256 ||= sha256_hexdigest(options[:body] || '')

        config = Aws::Crt::Auth::SigningConfig.new(
          algorithm: @signing_algorithm,
          signature_type: :http_request_query_params,
          region: @region,
          service: @service,
          date: datetime,
          signed_body_value: content_sha256,
          signed_body_header_type: @apply_checksum_header ?
            :sbht_content_sha256 : :sbht_none,
          credentials: creds,
          unsigned_headers: @unsigned_headers,
          use_double_uri_encode: @uri_escape_path,
          should_normalize_uri_path: @normalize_path,
          omit_session_token: @omit_session_token,
          expiration_in_seconds: options.fetch(:expires_in, 900)
        )
        signable = Aws::Crt::Auth::Signable.new(
          properties: { 'uri' => url.to_s, 'method' => http_method },
          property_lists: { 'headers' => headers }
        )

        signing_result = Aws::Crt::Auth::Signer.sign_request(config, signable)
        params = signing_result[:params].map {|k,v| "#{k}=#{v}"}.join('&')
        if url.query
          url.query += '&' + params
        else
          url.query = params
        end

        if options[:extra] && options[:extra].is_a?(Hash)
          options[:extra][:config] = config
          options[:extra][:signable] = signable
        end
        url
      end


      # Signs a event and returns signature headers and prior signature
      # used for next event signing.
      #
      # Headers of a sigv4 signed event message only contains 2 headers
      #   * ':chunk-signature'
      #     * computed signature of the event, binary string, 'bytes' type
      #   * ':date'
      #     * millisecond since epoch, 'timestamp' type
      #
      # Payload of the sigv4 signed event message contains eventstream encoded message
      # which is serialized based on input and protocol
      #
      # To sign events
      #
      #     headers_0, signature_0 = signer.sign_event(
      #       prior_signature, # hex-encoded string
      #       payload_0, # binary string (eventstream encoded event 0)
      #       encoder, # Aws::EventStreamEncoder
      #     )
      #
      #     headers_1, signature_1 = signer.sign_event(
      #       signature_0,
      #       payload_1, # binary string (eventstream encoded event 1)
      #       encoder
      #     )
      #
      # The initial prior_signature should be using the signature computed at initial request
      #
      # Note:
      #
      #   Since ':chunk-signature' header value has bytes type, the signature value provided
      #   needs to be a binary string instead of a hex-encoded string (like original signature
      #   V4 algorithm). Thus, when returning signature value used for next event siging, the
      #   signature value (a binary string) used at ':chunk-signature' needs to converted to
      #   hex-encoded string using #unpack
      def sign_event(prior_signature, payload, encoder)
        # CRT does not currently provide event stream signing
        # use the Ruby implementation
        creds = fetch_credentials
        time = Time.now
        headers = {}

        datetime = time.utc.strftime("%Y%m%dT%H%M%SZ")
        date = datetime[0,8]
        headers[':date'] = Aws::EventStream::HeaderValue.new(value: time.to_i * 1000, type: 'timestamp')

        sts = event_string_to_sign(datetime, headers, payload, prior_signature, encoder)
        sig = event_signature(creds.secret_access_key, date, sts)

        headers[':chunk-signature'] = Aws::EventStream::HeaderValue.new(value: sig, type: 'bytes')

        # Returning signed headers and signature value in hex-encoded string
        [headers, sig.unpack('H*').first]
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
        options[:region] || raise(Errors::MissingRegionError)
      end

      # The Credentials must be CRT native credentials
      # convert them and return a static provider
      def extract_credentials_provider(options)
        if options[:credentials_provider]
          credentials = options[:credentials_provider].credentials
          StaticCredentialsProvider.new(
            access_key_id: credentials.access_key_id,
            secret_access_key: credentials.secret_access_key,
            session_token: credentials.session_token
          )
        elsif options.key?(:credentials)
          credentials = options[:credentials]
          if credentials.is_a?(Aws::Crt::Auth::Credentials)
            StaticCredentialsProvider.new(options)
          else
            StaticCredentialsProvider.new(
              access_key_id: credentials.access_key_id,
              secret_access_key: credentials.secret_access_key,
              session_token: credentials.session_token
            )
          end
        elsif options.key?(:access_key_id)
          StaticCredentialsProvider.new(options)
        else
          raise Errors::MissingCredentialsError
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

      # Used only for event signing
      def credential_scope(date)
        [
          date,
          @region,
          @service,
          'aws4_request',
        ].join('/')
      end

      # Used only for event signing
      def hmac(key, value)
        OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, value)
      end

      # Compared to original #string_to_sign at signature v4 algorithm
      # there is no canonical_request concept for an eventstream event,
      # instead, an event contains headers and payload two parts, and
      # they will be used for computing digest in #event_string_to_sign
      #
      # Note:
      #   While headers need to be encoded under eventstream format,
      #   payload used is already eventstream encoded (event without signature),
      #   thus no extra encoding is needed.
      def event_string_to_sign(datetime, headers, payload, prior_signature, encoder)
        encoded_headers = encoder.encode_headers(
          Aws::EventStream::Message.new(headers: headers, payload: payload)
        )
        [
          "AWS4-HMAC-SHA256-PAYLOAD",
          datetime,
          credential_scope(datetime[0,8]),
          prior_signature,
          sha256_hexdigest(encoded_headers),
          sha256_hexdigest(payload)
        ].join("\n")
      end

      # Comparing to original signature v4 algorithm,
      # returned signature is a binary string instread of
      # hex-encoded string. (Since ':chunk-signature' requires
      # 'bytes' type)
      #
      # Note:
      #   converting signature from binary string to hex-encoded
      #   string is handled at #sign_event instead. (Will be used
      #   as next prior signature for event signing)
      def event_signature(secret_access_key, date, string_to_sign)
        k_date = hmac("AWS4" + secret_access_key, date)
        k_region = hmac(k_date, @region)
        k_service = hmac(k_region, @service)
        k_credentials = hmac(k_service, 'aws4_request')
        hmac(k_credentials, string_to_sign)
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
  end
end

# frozen_string_literal: true

require_relative 'spec_helper'

module Aws
  module Sigv4 #:nodoc:
    describe Signer do
      let(:credentials) {{
        access_key_id: 'AKIDEXAMPLE',
        secret_access_key: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
      }}

      let(:service_name) { 'service' }
      let(:region) { 'us-east-1' }

      let(:options) do
        {
          service: service_name,
          region: region,
          signing_algorithm: :v4a,
          apply_checksum_header: false,
          credentials_provider: StaticCredentialsProvider.new(credentials)
        }
      end

      context '#sign_request' do
        let(:timestamp) { "20150830T123600Z" }

        let(:request) do
          {
            http_method: 'GET',
            url: 'http://example.amazonaws.com',
            headers: {
              'X-Amz-Date' => timestamp
            }
          }
        end

      end
    end
  end
end

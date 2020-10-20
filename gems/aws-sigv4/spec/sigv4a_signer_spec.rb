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

        it 'signs the CRT suite vanilla request' do
          require 'json'
          signature = Signer.new(options).sign_request(request)
          puts signature
          prefix = File.expand_path('../v4a_suite/get-vanilla', __FILE__)
          expected_creq = File.read(File.join(prefix, 'canonical-request.txt'))
          expected_sts = File.read(File.join(prefix, 'header-string-to-sign.txt'))
          expected_pk = JSON.parse(File.read(File.join(prefix, 'public-key.json')))
          expected_req = SpecHelper.parse_request(File.read(File.join(prefix, 'header-signed-request.txt')))
          #expect(signature.canonical_request).to eq(expected_creq)
          #expect(signature.string_to_sign).to eq(expected_sts)
          #expect(signature.extra[:pk_x].to_s(16)).to eq expected_pk['X']
          #expect(signature.extra[:pk_y].to_s(16)).to eq expected_pk['Y']

          expected_req[:headers].each do |k,v|
            if k == 'Authorization'
              expected_parts = v.split(' ')
              actual_parts = signature.headers['authorization'].split(' ')
              expected_parts.zip(actual_parts).each do |e, a|
                expect(a).to eq(e)
              end
            end
            expect(signature.headers[k.downcase]).to eq(v)
          end
        end
      end
    end
  end
end

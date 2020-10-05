# frozen_string_literal: true

require_relative 'spec_helper'
require 'weakref'

module Aws
  module Crt
    module Auth #:nodoc:
      describe Signer do
        let(:properties) { { 'uri' => 'https://domain.com', 'method' => 'PUT' }}
        let(:headers) { { 'h1' => 'h1_v', 'h2' => 'h2_v', "content-length" => 9, "host"=>"domain.com" } } #{ { 'borkbork' => 'h1_v', 'someheader' => 'foo', 'foo'=> 'bar', 'h3' => 'h3_v', 'h4' => 'h4_value' } }
        let(:property_lists) { { 'headers' => headers } }

        it 'works' do
          creds = Credentials.new('akid', 'secret')
          config = SigningConfig.new(
            algorithm: :v4,
            signature_type: :http_request_headers,
            region: 'REGION',
            service: 'SERVICE',
            date: Time.parse('20120101T112233Z'),
            signed_body_value: '5c861aa8efc83488e5f0f006ca8d8ad54eb6541a0123b5c008cc40f9c7b7f202',
            credentials: creds,
            unsigned_headers: ['content-length']
          )
          signable = Signable.new(
            properties: properties,
            property_lists: property_lists
          )
          out = {}
          callback = proc do |result, status, _userdata|
            puts "\n---------------------\nSigning Completed, status: #{status}.  result: #{result}"
            # res = SigningResult.new(result)
            sig = Aws::Crt::Native.signing_result_get_property(result, 'signature')
            puts "Got sig: #{sig}"
            out[:sig] = sig
            p_list_p = Aws::Crt::Native.signing_result_get_property_list(result, 'headers')
            p_list = Aws::Crt::Native::PropertyList.new(p_list_p)
            out[:props] = p_list.props
            puts "Props: #{out[:props]}"

            nil
          end
          Aws::Crt::Native.sign_request(signable.native, config.native, 'my-test', callback)
          puts "At the end of the day:\n\tsig: #{out[:sig]}\n\tprops: #{out[:props]}"
        end

        it 'compares to sigv4a' do
          options = {
            access_key_id: 'akid',
            secret_access_key: 'secret',
            service: 'SERVICE',
            region: 'REGION',
            unsigned_headers: ['content-length']
          }
          require 'aws-sigv4'
          signature = Aws::Sigv4::Signer.new(options).sign_request(
            http_method: 'PUT',
            url: 'https://domain.com',
            headers: {
              'h1' => 'h1_v',
              'h2' => 'h2_v',
              "content-length" => 9,
              'X-Amz-Date' => '20120101T112233Z'
            },
            body: StringIO.new('http-body')
          )
          puts "\n-------------------------\nSDK Sigv4a:"
          puts signature.headers['authorization']
          puts "Canonical request: \n#{signature.canonical_request}"

          puts "string_to_sign: \n#{signature.string_to_sign}"
        end
      end
    end
  end
end

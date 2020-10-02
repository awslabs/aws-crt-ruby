# frozen_string_literal: true

require_relative 'spec_helper'
require 'weakref'

module Aws
  module Crt
    module Auth #:nodoc:
      describe Signer do
        let(:properties) { { 'uri' => 'test_uri', 'http_method' => 'GET' }}
        let(:headers) { { 'h1' => 'h1_v', 'h2' => 'h2_v' } }
        let(:property_lists) { { 'headers' => headers } }

        it 'works' do
          creds = Credentials.new('akid', 'secret')
          config = SigningConfig.new(
            algorithm: :v4,
            signature_type: :http_request_headers,
            region: 'us-west-2',
            service: 's3',
            signed_body_value: 'UNSIGNED-PAYLOAD',
            credentials: creds
          )
          signable = Signable.new(
            properties: properties,
            property_lists: property_lists
          )
          out = {}
          callback = proc do |result, status, userdata|
            puts "\n---------------------\nSigning Completed, status: #{status}.  result: #{result}"
            out[:result] = result
            nil
          end
          Aws::Crt::Native.sign_request(signable.native, config.native, 'my-test', callback)
          puts "Result: #{out[:result]}"
        end
      end
    end
  end
end

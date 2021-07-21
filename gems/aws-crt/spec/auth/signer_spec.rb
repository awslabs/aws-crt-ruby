# frozen_string_literal: true

require_relative '../spec_helper'

module Aws
  module Crt
    module Auth #:nodoc:
      describe Signer do
        describe '.sign_request' do
          let(:credentials) { StaticCredentialsProvider.new('akid', 'secret') }
          let(:region) { 'REGION' }
          let(:service) { 'SERVICE' }
          let(:date) { Time.parse('20120101T112233Z') }
          let(:signed_body_value) { 'UNSIGNED-PAYLOAD' }
          let(:signature_type) { :http_request_headers }
          let(:unsigned_headers) { nil }
          let(:signing_config) do
            SigningConfig.new(
              algorithm: :sigv4,
              signature_type: signature_type,
              region: region,
              service: service,
              date: date,
              credentials: credentials,
              signed_body_value: signed_body_value,
              unsigned_headers: unsigned_headers
            )
          end

          let(:http_request) do
            method = 'get'
            path = 'test_uri'
            headers = { 'h1' => 'h1_v', 'h2' => 'h2_v' }
            Aws::Crt::Http::Message.new(method, path, headers)
          end

          let(:signable) do
            Signable.new(http_request)
          end

          it 'returns the signature' do
            res = Signer.sign_request(signing_config, signable)
            expect(res[:signature]).not_to be_nil
            expect(res[:signature]).to eq(
              '192cb64eb7907ded2610529ac08db975380c16acb4f226de734c08c4784697f3'
            )
          end

          it 'returns the headers' do
            res = Signer.sign_request(signing_config, signable)
            expect(res[:headers]).not_to be_nil
            expect(res[:headers]).to be_a_kind_of(Hash)
          end

          it 'sets the Authorization header' do
            res = Signer.sign_request(signing_config, signable)
            expect(res[:headers]['Authorization'])
              .to include "Signature=#{res[:signature]}"
          end

          it 'sets the x-amz-content-sha256 header' do
            res = Signer.sign_request(signing_config, signable)
            expect(res[:headers]['x-amz-content-sha256'])
              .to eq(signed_body_value)
          end

          it 'includes passed headers in the SignedHeaders' do
            res = Signer.sign_request(signing_config, signable)
            expect(res[:headers]['Authorization'])
              .to include 'SignedHeaders=h1;h2'
          end

          context 'unsigned_headers set' do
            let(:unsigned_headers) { ['h1'] }

            it 'does not include unsigned_headers in SignedHeaders' do
              res = Signer.sign_request(signing_config, signable)
              expect(res[:headers]['Authorization'])
                .to include 'SignedHeaders=h2'
            end
          end

          # context 'stress test' do
          #   let(:n_test_threads) { 5 }
          #   let(:test_duration) { 2 }
          #
          #   it 'is stable under multiple threads' do
          #     shutdown_threads = false
          #     threads = []
          #     expected_signature = '1647c6a6a79fb9eddaa5f69459c50152e8fa32e' \
          #       'f453526ae113b1e1cb48c1c0e'
          #
          #     failures = Array.new(n_test_threads, 0)
          #
          #     n_test_threads.times do |i|
          #       threads << Thread.new do
          #         until shutdown_threads
          #           signing_config = SigningConfig.new(
          #             algorithm: :sigv4,
          #             signature_type: :http_request_headers,
          #             region: 'REGION',
          #             service: 'SERVICE',
          #             date: Time.parse('20120101T112233Z'),
          #             credentials: Credentials.new('akid', 'secret'),
          #             signed_body_value: 'UNSIGNED-PAYLOAD',
          #             unsigned_headers: ['unsigned']
          #           )
          #           signable = Signable.new(
          #             properties:
          #               { 'uri' => 'test_uri', 'http_method' => 'get' },
          #             property_lists:
          #               { 'headers' =>
          #                   {
          #                     'h1' => 'h1_v',
          #                     'h2' => 'h2_v',
          #                     'unsigned' => 'unsigned_value'
          #                   } }
          #           )
          #           res = Signer.sign_request(signing_config, signable)
          #           failures[i] += 1 if res[:signature] != expected_signature
          #         end
          #       end
          #     end
          #
          #     # run a stress test for a few seconds.
          #     # Increase this to stress test more locally
          #     sleep(test_duration)
          #     shutdown_threads = true
          #     threads.each(&:join)
          #
          #     expect(failures.all?(&:zero?)).to be true
          #   end
          # end
        end
      end
    end
  end
end

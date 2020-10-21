# frozen_string_literal: true

require_relative 'spec_helper'
require 'json'
require 'time'

module Aws
  module Sigv4
    describe Signer do
      describe 'sigv4a suite' do
        Dir.glob(File.expand_path('../v4a_suite/**', __FILE__)).each do |path|

          next unless File.exist?(File.join(path, 'request.txt'))
          next unless File.exist?(File.join(path, 'context.json'))
          next unless File.exist?(File.join(path, 'header-canonical-request.txt'))

          describe(File.basename(path)) do

            let(:context) do
              JSON.parse(File.read(File.join(path, 'context.json')))
            end

            let(:signer) do
              Signer.new({
                 service: context['service'],
                 region: context['region'],
                 signing_algorithm: :v4a,
                 credentials: Aws::Crt::Auth::Credentials.new(
                   context['credentials']['access_key_id'],
                   context['credentials']['secret_access_key'],
                   context['credentials']['token']
                 ),
                 uri_escape_path: false, #context['normalize'],
                 apply_checksum_header: context['sign_body']
               })
            end

            let(:request_time) do
              Time.parse(context['timestamp']) if context['timestamp']
            end

            let(:request) do
              raw_request = File.read(
                File.join(path, 'request.txt'), encoding: "utf-8"
              )
              request = SpecHelper.parse_request(raw_request, context['normalize'])
              if request_time
                request[:headers]['x-amz-date'] = request_time.utc.strftime('%Y%m%dT%H%M%SZ')
              end
              SpecHelper.debug("GIVEN REQUEST: |#{raw_request}|")
              SpecHelper.debug("PARSED REQUEST: #{request.inspect}")
              request
            end

            it 'computes the authorization header' do
              signature = signer.sign_request(request)
              creq = File.read(
                File.join(path, 'header-canonical-request.txt'), encoding: "utf-8"
              )
              expected_pk = JSON.parse(File.read(File.join(path, 'public-key.json')))

              expected_req = SpecHelper.parse_request(File.read(File.join(path, 'header-signed-request.txt')))
              expected_req[:headers].each do |k,v|
                if k == 'Authorization'
                  expected_parts = v.split(' ')
                  actual_parts = signature.headers['authorization'].split(' ')
                  expected_parts.zip(actual_parts).each do |e, a|
                    if e.start_with?('Signature')
                      # Both signatures should verify but wont match
                      # since ECCDA relies on a random k value
                      config = signature.extra[:config]
                      signable = signature.extra[:signable]
                      Aws::Crt::Native.verify_sigv4a_signing(
                        signable.native,
                        config.native,
                        creq,
                        e.split('=')[1],
                        expected_pk['X'],
                        expected_pk['Y']
                      )

                      Aws::Crt::Native.verify_sigv4a_signing(
                        signable.native,
                        config.native,
                        creq,
                        a.split('=')[1],
                        expected_pk['X'],
                        expected_pk['Y']
                      )
                    else
                      expect(a).to eq(e)
                    end
                  end
                else
                  expect(signature.headers[k.downcase] || request[:headers][k]).to eq(v)
                end
              end
            end
          end
        end
      end
    end
  end
end

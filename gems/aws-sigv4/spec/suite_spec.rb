# # frozen_string_literal: true
#
# require_relative 'spec_helper'
#
# module Aws
#   module Sigv4
#     describe Signer do
#       describe 'suite' do
#         Dir.glob(File.expand_path('../suite/**', __FILE__)).each do |path|
#
#           prefix = File.join(path, File.basename(path))
#           next unless File.exist?("#{prefix}.req")
#
#           describe(File.basename(prefix)) do
#
#             let(:signer) {
#               Signer.new({
#                 service: 'service',
#                 region: 'us-east-1',
#                 credentials: Aws::Crt::Auth::Credentials.new(
#                   'AKIDEXAMPLE',
#                   'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
#                 ),
#                 # necessary to pass the test suite
#                 uri_escape_path: false,
#                 apply_checksum_header: false,
#               })
#             }
#
#             let(:request) {
#               raw_request = File.read("#{prefix}.req", encoding: "utf-8")
#               request = SpecHelper.parse_request(raw_request)
#               SpecHelper.debug("GIVEN REQUEST: |#{raw_request}|")
#               request
#             }
#
#             # CRT does not return canonical request
#             # it 'computes the canonical request' { }
#
#             # CRT does not return the string to sign
#             # it 'computes the string to sign' { }
#
#             it 'computes the authorization header' do # authz
#               signature = signer.sign_request(request)
#               computed = signature.headers['authorization']
#               expected = File.read("#{prefix}.authz", encoding: "utf-8")
#               SpecHelper.debug("EXPECTED AUTHORIZATION: |#{expected}|")
#               SpecHelper.debug("COMPUTED AUTHORIZATION: |#{computed}|")
#               expect(computed).to eq(expected)
#             end
#           end
#         end
#       end
#     end
#   end
# end

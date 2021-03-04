# frozen_string_literal: true

require_relative 'spec_helper'
require 'weakref'

module Aws
  module Crt
    module Auth #:nodoc:
      InvalidConfigError = Aws::Crt::Errors.error_class(
        'AWS_AUTH_SIGNING_INVALID_CONFIGURATION'
      )
      describe SigningConfig do
        describe '#initialize' do
          it 'constructs the object' do
            creds = Credentials.new('akid', 'secret')
            expect do
              SigningConfig.new(
                algorithm: :sigv4,
                signature_type: :http_request_headers,
                region: 'us-west-2',
                service: 's3',
                credentials: creds
              )
            end.not_to raise_error
          end

          it 'constructs the object with a signed_body_value' do
            creds = Credentials.new('akid', 'secret')
            expect do
              SigningConfig.new(
                algorithm: :sigv4,
                signature_type: :http_request_headers,
                region: 'us-west-2',
                service: 's3',
                signed_body_value: 'UNSIGNED-PAYLOAD',
                credentials: creds
              )
            end.not_to raise_error
          end

          it 'raises an InvalidConfigError when missing a required parameter' do
            expect do
              SigningConfig.new(
                algorithm: :sigv4,
                signature_type: :http_request_headers,
                region: 'us-west-2',
                service: 's3',
                credentials: nil
              )
            end.to raise_error(InvalidConfigError)
          end
        end

        describe '.on_release' do
          # NOTE: Cannot use let with GC tests
          it 'cleans up with release' do
            creds = Credentials.new('akid', 'secret')
            config = SigningConfig.new(
              algorithm: :sigv4,
              signature_type: :http_request_headers,
              region: 'us-west-2',
              service: 's3',
              credentials: creds
            )

            expect(config).to_not be_nil

            config.release
            check_for_clean_shutdown
          end

          if garbage_collect_is_immediate?
            it 'cleans up with GC' do
              creds = Credentials.new('akid', 'secret')
              config = SigningConfig.new(
                algorithm: :sigv4,
                signature_type: :http_request_headers,
                region: 'us-west-2',
                service: 's3',
                credentials: creds
              )
              weakref = WeakRef.new(config)
              expect(weakref.weakref_alive?).to be true

              # force cleanup via GC
              config = nil # rubocop:disable Lint/UselessAssignment
              ObjectSpace.garbage_collect
              expect(weakref.weakref_alive?).to be_falsey
              check_for_clean_shutdown
            end
          end
        end
      end
    end
  end
end

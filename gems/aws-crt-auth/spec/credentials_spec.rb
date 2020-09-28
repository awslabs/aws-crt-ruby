# frozen_string_literal: true

require_relative 'spec_helper'
require 'weakref'

module Aws
  module Crt
    module Auth #:nodoc:
      UINT64_MAX = 18_446_744_073_709_551_615

      describe Credentials do
        describe '#initilize' do
          it 'raises an ArgumentError when missing access_key_id' do
            expect { Credentials.new(nil, 'secret') }
              .to raise_error(ArgumentError)
          end

          it 'raises an ArgumentError when missing secret_access_key' do
            expect { Credentials.new('akid', nil) }
              .to raise_error(ArgumentError)
          end

          it 'defaults the session token to nil' do
            expect(Credentials.new('akid', 'secret').session_token).to be nil
          end

          it 'defaults the expiration to UINT64_MAX' do
            expect(Credentials.new('akid', 'secret').expiration.to_i)
              .to eq UINT64_MAX
          end

          it 'accepts a Time for expiration' do
            exp = Time.now
            creds = Credentials.new('akid', 'secret', 'token', exp)
            expect(creds.expiration.to_i).to eq exp.to_i
          end

          it 'accepts an epoch (integer) for expiration' do
            exp = Time.now
            creds = Credentials.new('akid', 'secret', 'token', exp.to_i)
            expect(creds.expiration.to_i).to eq exp.to_i
          end
        end

        describe 'accessors' do
          let(:exp) { Time.now }
          let(:creds) { Credentials.new('akid', 'secret', 'token', exp) }

          it 'provides access to the access key id' do
            expect(creds.access_key_id).to eq('akid')
          end

          it 'provides access to the secret access key' do
            expect(creds.secret_access_key).to eq('secret')
          end

          it 'provides access to the session token' do
            expect(creds.session_token).to eq('token')
          end

          it 'provides access to the expiration' do
            expect(creds.expiration.to_i).to eq exp.to_i
          end
        end

        describe '#set?' do
          it 'returns true when the key and secret are both non nil values' do
            expect(Credentials.new('akid', 'secret').set?).to be(true)
          end

          it 'returns false after the credentials have been released' do
            creds = Credentials.new('akid', 'secret')
            creds.release
            expect(creds.set?).to be(false)
          end
        end

        describe '#inspect' do
          let(:creds) { Credentials.new('akid', 'secret', 'token') }

          it 'does not include the secret_access_key' do
            expect(creds.inspect).not_to include 'secret'
          end
        end

        describe '.on_release' do
          it 'cleans up with release' do
            creds = Credentials.new('akid', 'secret')
            expect(creds).to_not be_nil

            creds.release
            check_for_clean_shutdown
          end

          if garbage_collect_is_immediate?
            it 'cleans up with GC' do
              creds = Credentials.new('akid', 'secret', 'session')
              weakref = WeakRef.new(creds)
              expect(weakref.weakref_alive?).to be true

              # force cleanup via GC
              creds = nil # rubocop:disable Lint/UselessAssignment
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

# frozen_string_literal: true

require_relative '../spec_helper'
require 'weakref'

module Aws
  module Crt
    module Auth # :nodoc:
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

          it 'accepts a Time for expiration' do
            exp = Time.now
            Credentials.new('akid', 'secret', 'token', exp)
          end

          it 'accepts an epoch (integer) for expiration' do
            exp = Time.now
            Credentials.new('akid', 'secret', 'token', exp.to_i)
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

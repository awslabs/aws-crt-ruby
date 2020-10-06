# frozen_string_literal: true

require_relative 'spec_helper'
require 'weakref'

module Aws
  module Crt
    module Auth #:nodoc:
      describe Signable do
        let(:properties) { { 'uri' => 'test_uri', 'http_method' => 'get' } }
        let(:headers) { { 'h1' => 'h1_v', 'h2' => 'h2_v' } }
        let(:property_lists) { { 'headers' => headers } }

        describe '#initialize' do
          it 'creates the native object' do
            signable = Signable.new(
              properties: properties,
              property_lists: property_lists
            )
            expect(signable).not_to be_nil
            expect(signable.native).to be_a_kind_of(FFI::AutoPointer)
          end
        end

        describe '.on_release' do
          # Note: Cannot use let with GC tests
          it 'cleans up with release' do
            signable = Signable.new(
              properties: properties,
              property_lists: property_lists
            )

            expect(signable).to_not be_nil

            signable.release
            check_for_clean_shutdown
          end

          if garbage_collect_is_immediate?
            it 'cleans up with GC' do
              signable = Signable.new(
                properties: properties,
                property_lists: property_lists
              )
              weakref = WeakRef.new(signable)
              expect(weakref.weakref_alive?).to be true

              # force cleanup via GC
              signable = nil # rubocop:disable Lint/UselessAssignment
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

# frozen_string_literal: true

require_relative '../spec_helper'

module Aws
  module Crt
    module Auth # :nodoc:
      describe Signable do
        let(:http_request) do
          method = 'GET'
          path = 'http://example.com/'
          headers = { 'header1' => 'value1', 'header2' => 'value2' }
          Aws::Crt::Http::Message.new(method, path, headers)
        end

        describe '#initialize' do
          it 'creates the native object' do
            signable = Signable.new(http_request)
            expect(signable).not_to be_nil
            expect(signable.native).to be_a_kind_of(FFI::AutoPointer)
          end
        end

        describe '.on_release' do
          # NOTE: Cannot use let with GC tests
          it 'cleans up with release' do
            signable = Signable.new(http_request)

            expect(signable).to_not be_nil

            signable.release
            check_for_clean_shutdown
          end

          if garbage_collect_is_immediate?
            it 'cleans up with GC' do
              request = Aws::Crt::Http::Message.new(
                'GET',
                'http://example.com/',
                { header1: 'value1', header2: 'value2' }
              )

              signable = Signable.new(request) # rubocop:disable Lint/UselessAssignment
              request = nil # rubocop:disable Lint/UselessAssignment
              signable = nil # rubocop:disable Lint/UselessAssignment

              GC.start(full_mark: true, immediate_sweep: true)
              check_for_clean_shutdown
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../spec_helper'
require 'weakref'
require 'timeout'

describe Aws::Crt::IO::EventLoopGroup do
  it 'cleans up with release' do
    elg = Aws::Crt::IO::EventLoopGroup.new
    expect(elg).to_not be_nil

    elg.release
    check_for_clean_shutdown
  end

  if garbage_collect_is_immediate?
    it 'cleans up with GC' do
      elg = Aws::Crt::IO::EventLoopGroup.new
      weakref = WeakRef.new(elg)
      expect(weakref.weakref_alive?).to be true

      # force cleanup via GC
      elg = nil # rubocop:disable Lint/UselessAssignment

      # Use polling with time limit for GC collection to avoid flaky failures.
      begin
        Timeout.timeout(3) do
          while weakref.weakref_alive?
            GC.start(full_mark: true, immediate_sweep: true)
            Thread.pass
          end
        end
      rescue Timeout::Error
        raise 'Expected GC to collect the EventLoopGroup within 2 seconds'
      end

      check_for_clean_shutdown
    end
  end
end

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

  def event_loop_group_weakref
    elg = Aws::Crt::IO::EventLoopGroup.new
    WeakRef.new(elg)
  end

  # Test disabled in osx bc of more conservative GC timing.
  # Related forum post: https://bugs.ruby-lang.org/issues/19041?utm
  it 'cleans up with GC', skip: RUBY_PLATFORM.include?('darwin') do
    weakref = event_loop_group_weakref
    expect(weakref.weakref_alive?).to be true

    begin
      Timeout.timeout(3) do
        while weakref.weakref_alive?
          GC.start(full_mark: true, immediate_sweep: true)
          Thread.pass
        end
      end
    rescue Timeout::Error
      raise 'Expected GC to collect the EventLoopGroup within 3 seconds'
    end

    check_for_clean_shutdown
  end
end

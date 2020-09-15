# frozen_string_literal: true

require 'spec_helper'
require 'weakref'

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
      ObjectSpace.garbage_collect
      expect(weakref.weakref_alive?).to be_falsey
      check_for_clean_shutdown
    end
  end
end

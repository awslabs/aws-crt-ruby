# frozen_string_literal: true

require_relative '../spec_helper'

describe Aws::Crt::IO::EventLoopGroup do
  it 'cleans up with release' do
    elg = Aws::Crt::IO::EventLoopGroup.new
    expect(elg).to_not be_nil

    elg.release
    check_for_clean_shutdown
  end

  # Test disabled in osx bc of more conservative GC timing.
  # Related forum post: https://bugs.ruby-lang.org/issues/19041?utm
  it 'cleans up with GC', skip: RUBY_PLATFORM.include?('darwin') do
    elg = Aws::Crt::IO::EventLoopGroup.new # rubocop:disable Lint/UselessAssignment
    elg = nil # rubocop:disable Lint/UselessAssignment

    GC.start(full_mark: true, immediate_sweep: true)
    check_for_clean_shutdown
  end
end

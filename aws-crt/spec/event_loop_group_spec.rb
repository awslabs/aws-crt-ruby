require 'spec_helper'
require 'weakref'

describe Aws::Crt::IO::EventLoopGroup do
  it 'lives and dies' do
    # create
    elg = Aws::Crt::IO::EventLoopGroup.new
    expect(elg).to_not be_nil
    weakref = WeakRef.new(elg)
    expect(weakref.weakref_alive?).to be_truthy

    # destroy
    elg = nil
    ObjectSpace.garbage_collect
    expect(weakref.weakref_alive?).to be_falsey

    check_for_clean_shutdown
  end
end

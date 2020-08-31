require 'spec_helper'

describe Aws::Crt::IO do
  it 'has a test' do
    elg = Aws::Crt::IO::EventLoopGroup.new
    elg.destroy
  end
end

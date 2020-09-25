# frozen_string_literal: true

require_relative 'spec_helper'

describe Aws::Crt::Auth do
  it 'defines the namespace' do
    expect(Module.const_defined?('Aws::Crt::Auth')).to be true
  end
end

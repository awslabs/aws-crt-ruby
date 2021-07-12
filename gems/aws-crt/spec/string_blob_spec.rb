# frozen_string_literal: true

require_relative 'spec_helper'

describe Aws::Crt::StringBlob do
  it 'encodes and decodes' do
    strings = ['test string ascii only',
               'test string with multibyte unicode: ह']
    buffer = Aws::Crt::StringBlob::encode(strings)
    strings_out = Aws::Crt::StringBlob::decode(buffer)
    expect(strings_out).to eq strings
  end
end

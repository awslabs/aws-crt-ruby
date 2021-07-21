# frozen_string_literal: true

require_relative '../spec_helper'

describe Aws::Crt::Http::Message do
  it 'constructs from method, path and headers' do
    method = 'GET'
    path = 'http://example.com'
    headers = { 'header1' => 'value1', 'header2' => 'value2' }
    http_request = Aws::Crt::Http::Message.new(method, path, headers)
    expect(http_request.native).to_not be_nil

    expect(http_request.method).to eq method
    expect(http_request.path).to eq path
    expect(http_request.headers).to eq headers

    http_request.release
  end
end

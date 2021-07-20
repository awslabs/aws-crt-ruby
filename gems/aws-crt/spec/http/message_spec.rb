# frozen_string_literal: true

require_relative '../spec_helper'

describe Aws::Crt::Http::Message do
  it 'constructs from method, path and headers' do
    method = 'GET'
    path = 'http://example.com'
    headers = { 'header1' => 'value1', 'header2' => 'value2' }
    crt_message = Aws::Crt::Http::Message.new(method, path, headers)
    expect(crt_message.native).to_not be_nil

    # TODO: message_to_blob does not work - the blob returned has zero length
    blob_out = crt_message.to_blob_strings
    expected_header_blob = headers.each_pair { |k, v| [k, v] }.flatten
    expect(blob_out[0]).to eq method
    expect(blob_out[1]).to eq path
    expect(blob_out[2..blob_out.length]).to eq expected_header_blob

    crt_message.release
  end
end

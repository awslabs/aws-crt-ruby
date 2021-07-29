# frozen_string_literal: true

require_relative '../spec_helper'

describe Aws::Crt::Http::Headers do
  it 'constructs from hash of headers' do
    headers = { 'header1' => 'value1', 'header2' => 'value2' }
    crt_headers = Aws::Crt::Http::Headers.new(headers)
    expect(crt_headers.native).to_not be_nil

    blob_out = crt_headers.to_blob_strings
    expected_header_blob = headers.flatten
    expect(blob_out).to eq expected_header_blob

    crt_headers.release
  end
end

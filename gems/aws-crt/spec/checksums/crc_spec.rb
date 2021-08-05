# frozen_string_literal: true

require_relative '../spec_helper'
require 'base64'

def int32_to_base64(num)
  Base64.encode64([num].pack('N'))
end

describe Aws::Crt::Checksums do
  describe 'crc32' do
    test_cases = [
      { str: '', expected: "AAAAAA==\n" },
      { str: 'abc', expected: "NSRBwg==\n" },
      { str: 'Hello world', expected: "i9aeUg==\n" }
    ]
    test_cases.each do |test_case|
      it "produces the correct checksum for '#{test_case[:str]}'" do
        checksum = int32_to_base64(Aws::Crt::Checksums.crc32(test_case[:str]))
        expect(checksum).to eq(test_case[:expected])
      end
    end
  end

  describe 'crc32c' do
    test_cases = [
      { str: '', expected: "AAAAAA==\n" },
      { str: 'abc', expected: "Nks/tw==\n" },
      { str: 'Hello world', expected: "crUfeA==\n" }
    ]
    test_cases.each do |test_case|
      it "produces the correct checksum for '#{test_case[:str]}'" do
        checksum = int32_to_base64(Aws::Crt::Checksums.crc32c(test_case[:str]))
        expect(checksum).to eq(test_case[:expected])
      end
    end
  end
end

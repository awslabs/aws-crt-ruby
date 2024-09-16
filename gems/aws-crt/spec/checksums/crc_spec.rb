# frozen_string_literal: true

require_relative '../spec_helper'
require 'base64'

def int32_to_base64(num)
  Base64.encode64([num].pack('N'))
end

ZERO_CHAR = [0].pack('C*')
INT_MAX = (2**32) - 1

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

    it 'works with zeros in one shot' do
      output = Aws::Crt::Checksums.crc32(ZERO_CHAR * 32)
      expect(output).to eq(0x190A55AD)
    end

    it 'works with zeros iterated' do
      output = 0
      32.times do
        output = Aws::Crt::Checksums.crc32(ZERO_CHAR, output)
      end
      expect(output).to eq(0x190A55AD)
    end

    it 'works with values in one shot' do
      buf = (0...32).to_a.pack('C*')
      output = Aws::Crt::Checksums.crc32(buf)
      expect(output).to eq(0x91267E8A)
    end

    it 'works with values iterated' do
      output = 0
      32.times do |i|
        output = Aws::Crt::Checksums.crc32([i].pack('C*'), output)
      end
      expect(output).to eq(0x91267E8A)
    end

    it 'works with a large buffer' do
      output = Aws::Crt::Checksums.crc32(ZERO_CHAR * 25 * (2**20))
      expect(output).to eq(0x72103906)
    end

    it 'works with a huge buffer' do
      output = Aws::Crt::Checksums.crc32(ZERO_CHAR * (INT_MAX + 5))
      expect(output).to eq(0xc622f71d)
    rescue NoMemoryError, RangeError
      skip 'Unable to allocate memory for crc32 huge buffer test'
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

    it 'works with zeros in one shot' do
      output = Aws::Crt::Checksums.crc32c(ZERO_CHAR * 32)
      expect(output).to eq(0x8A9136AA)
    end

    it 'works with zeros iterated' do
      output = 0
      32.times do
        output = Aws::Crt::Checksums.crc32c(ZERO_CHAR, output)
      end
      expect(output).to eq(0x8A9136AA)
    end

    it 'works with values in one shot' do
      buf = (0...32).to_a.pack('C*')
      output = Aws::Crt::Checksums.crc32c(buf)
      expect(output).to eq(0x46DD794E)
    end

    it 'works with values iterated' do
      output = 0
      32.times do |i|
        output = Aws::Crt::Checksums.crc32c([i].pack('C*'), output)
      end
      expect(output).to eq(0x46DD794E)
    end

    it 'works with a large buffer' do
      output = Aws::Crt::Checksums.crc32c(ZERO_CHAR * 25 * (2**20))
      expect(output).to eq(0xfb5b991d)
    end

    it 'works with a huge buffer' do
      output = Aws::Crt::Checksums.crc32c(ZERO_CHAR * (INT_MAX + 5))
      expect(output).to eq(0x572a7c8a)
    rescue NoMemoryError, RangeError
      skip 'Unable to allocate memory for crc32c huge buffer test'
    end
  end

  describe 'crc64nvme' do
    test_cases = [
      { str: '', expected: "AAAAAA==\n" },
      { str: 'abc', expected: "P8H66w==\n" },
      { str: 'Hello world', expected: "PzEq2w==\n" }
    ]
    test_cases.each do |test_case|
      it "produces the correct checksum for '#{test_case[:str]}'" do
        checksum = int32_to_base64(
          Aws::Crt::Checksums.crc64nvme(test_case[:str])
        )
        expect(checksum).to eq(test_case[:expected])
      end
    end

    it 'works with zeros in one shot' do
      output = Aws::Crt::Checksums.crc64nvme(ZERO_CHAR * 32)
      expect(output).to eq(0xCF3473434D4ECF3B)
    end

    it 'works with zeros iterated' do
      output = 0
      32.times do
        output = Aws::Crt::Checksums.crc64nvme(ZERO_CHAR, output)
      end
      expect(output).to eq(0xCF3473434D4ECF3B)
    end

    it 'works with values in one shot' do
      buf = (0...32).to_a.pack('C*')
      output = Aws::Crt::Checksums.crc64nvme(buf)
      expect(output).to eq(0xB9D9D4A8492CBD7F)
    end

    it 'works with a large buffer' do
      output = Aws::Crt::Checksums.crc64nvme(ZERO_CHAR * 25 * (2**20))
      expect(output).to eq(0x5B6F5045463CA45E)
    end

    it 'works with a huge buffer' do
      output = Aws::Crt::Checksums.crc64nvme(ZERO_CHAR * (INT_MAX + 5))
      expect(output).to eq(0x2645C28052B1FBB0)
    rescue NoMemoryError, RangeError
      skip 'Unable to allocate memory for crc32c huge buffer test'
    end
  end
end

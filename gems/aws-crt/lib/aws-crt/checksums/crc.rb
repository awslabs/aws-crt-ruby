# frozen_string_literal: true

module Aws
  module Crt
    # High level Ruby abstractions for CRT Checksums functionality
    module Checksums
      def self.crc32(str, previous = 0)
        Aws::Crt::Native.crc32(
          FFI::MemoryPointer.from_string(str),
          str.size,
          previous
        )
      end

      def self.crc32c(str, previous = 0)
        Aws::Crt::Native.crc32c(
          FFI::MemoryPointer.from_string(str),
          str.size,
          previous
        )
      end
    end
  end
end

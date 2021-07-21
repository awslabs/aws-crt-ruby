# frozen_string_literal: true

require 'stringio'

module Aws
  module Crt
    # module for CRT Blob utility methods
    # CRT encodes lists of strings as [length, str*]
    # using null padded, unsigned long
    module StringBlob
      # Encode an array of strings into
      # a buffer (blob)
      # @param strings [Array<String>]
      # @return buffer (Array<char>)
      def self.encode(strings)
        buffer = StringIO.new
        strings.each do |s|
          e = s.to_s.unpack('c*')
          buffer << [e.length].pack('N')
          buffer << (e).pack('c*')
        end
        buffer.string.unpack('c*')
      end

      # Decode a blob (StringBlob)/Buffer into
      # an array of strings
      # @param buffer - array of chars (buffer)
      # @return strings
      def self.decode(buffer)
        strings = []
        i = 0
        while i < buffer.size
          len = buffer[i, 4].pack('c*').unpack1('N')
          strings << (buffer[i + 4, len].pack('c*'))
                     .force_encoding(Encoding::UTF_8)
          i += len + 4
        end
        strings
      end
    end
  end
end

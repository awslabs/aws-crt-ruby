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
      # @return buffer (StringBlob)
      def self.encode(strings)
        buffer = StringIO.new
        strings.each do |s|
          e = s.unpack('c*') + [0]
          buffer << [e.length].pack('L')
          buffer << (e).pack('c*')
        end
        buffer.string
      end

      # Decode a blob (StringBlob)/Buffer into
      # an array of strings
      # @param buffer
      # @return strings
      def self.decode(buffer)
        strings = []

        # concert to a byte array
        buffer = buffer.unpack('c*')
        i = 0
        while i < buffer.size
          len = buffer[i, 4].pack('c*').unpack1('L')
          strings << (buffer[i + 4, len - 1].pack('c*'))
                     .force_encoding(Encoding::UTF_8)
          i += len + 4
        end
        strings
      end
    end
  end
end
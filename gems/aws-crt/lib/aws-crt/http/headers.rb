# frozen_string_literal: true

module Aws
  module Crt
    # High level Ruby abstractions for CRT HTTP functionality
    module Http
      # HTTP Headers
      class Headers
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(
          :http_headers_release
        )

        def initialize(headers = {})
          blob = StringBlob.encode(headers.each_pair { |k, v| [k, v] }.flatten)
          blob_ptr = FFI::MemoryPointer.new(:char, blob.length)
          blob_ptr.write_array_of_char(blob)

          manage_native do
            Aws::Crt::Native.http_headers_new_from_blob(blob_ptr, blob.length)
          end
        end

        def to_blob_strings
          buf_out = Aws::Crt::Native::CrtBuf.new
          Aws::Crt::Native.http_headers_to_blob(native, buf_out)
          StringBlob.decode(buf_out.to_blob)
        end
      end
    end
  end
end

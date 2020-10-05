# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Signing Config
      class Signable
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:signable_release)

        # @param [Hash] options
        # @option options [required, Hash[String,String]] :properties - Hash
        #   of String->String.  Should include properties for: uri, http_method
        # @option options [required, Hash[String,Hash[String,String]]]
        #   :property_lists - Should include headers.
        def initialize(options = {})
          manage_native do
            Aws::Crt::Native.signable_new
          end

          options.fetch(:properties, {}).each do |k, v|
            Aws::Crt::Native.signable_set_property(native, k, v)
          end

          options.fetch(:property_lists, {}).each do |k, h|
            count = h.size
            key_array = FFI::MemoryPointer.new(:pointer, count)
            value_array = FFI::MemoryPointer.new(:pointer, count)
            key_array.write_array_of_pointer(h.keys.map { |s| FFI::MemoryPointer.from_string(s) })
            value_array.write_array_of_pointer(h.values.map { |s| FFI::MemoryPointer.from_string(s) })
            Aws::Crt::Native.signable_set_property_list(native, k, count, key_array, value_array)
          end
        end
      end
    end
  end
end

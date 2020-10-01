# frozen_string_literal: true

require_relative 'spec_helper'
require 'weakref'

module Aws
  module Crt
    module Auth #:nodoc:
      describe Signable do
        it 'works' do
          ptr = Aws::Crt::Native.signable_new
          puts ptr
          puts Aws::Crt::Native.signable_set_property(ptr, 'name', 'value')
          puts Aws::Crt::Native.signable_get_property(ptr, 'name')

          puts Aws::Crt::Native.signable_append_property_list(ptr, 'p1', 'k1', 'v1')
          puts Aws::Crt::Native.signable_append_property_list(ptr, 'p1', 'k2', 'v2')
          puts Aws::Crt::Native.signable_append_property_list(ptr, 'p2', 'k1', 'v1')

          h = {'k1' => 'v1', 'k2' => 'v2'}
          count = h.size
          key_array = FFI::MemoryPointer.new(:pointer, count)
          value_array = FFI::MemoryPointer.new(:pointer, count)
          key_array.write_array_of_pointer(h.keys.map {|s| FFI::MemoryPointer.from_string(s)})
          value_array.write_array_of_pointer(h.keys.map {|s| FFI::MemoryPointer.from_string(s)})
          puts Aws::Crt::Native.signable_set_property_list(ptr, 'p3', count, key_array, value_array)



          Aws::Crt::Native.signable_release(ptr)
        end
      end
    end
  end
end

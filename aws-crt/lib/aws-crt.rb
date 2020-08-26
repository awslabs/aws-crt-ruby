# Must be defined before require
module Aws
  module Crt
    class MyMalloc
      VERSION = "1.0"
    end
  end
end

require "aws-crt/aws_crt"

require 'ffi'

COMMON_BIN_PATH = File.expand_path("../bin/libaws-c-common", File.dirname(__FILE__))

module CRT
  extend FFI::Library
  ffi_lib [COMMON_BIN_PATH, 'libaws-c-common']
  attach_function :aws_high_res_clock_get_ticks, [ :pointer ], :int

  def self.mytime
    p = FFI::MemoryPointer.new(:uint64)
    CRT::aws_high_res_clock_get_ticks(p)
    # p.read(:uint64)  # read is not supported in jruby version?
    p.get_uint64(0)
  end
end
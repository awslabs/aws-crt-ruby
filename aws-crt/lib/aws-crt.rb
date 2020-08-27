require 'ffi'

# Maps platform to crt binary name.  Needs to match what is used in the Rakefile for builds
PLATFORMS = {
  "universal-darwin" => 'libaws-crt.dylib'
}.freeze

def host_string
  "#{host_cpu}-#{host_os}"
end

# @return [String] host cpu, even on jruby
def host_cpu
  case RbConfig::CONFIG["host_cpu"]
  when /86_64/
    "x86_64"
  when /86/
    "x86"
  else
    RbConfig::CONFIG["host_cpu"]
  end
end

# @return [String] host os, even on jruby
def host_os
  case RbConfig::CONFIG["host_os"]
  when /darwin/
    "darwin"
  when /linux/
    "linux"
  when /mingw|mswin/
    "mingw32"
  else
    RbConfig::CONFIG["host_os"]
  end
end

platform = PLATFORMS.keys.find { |p| Gem::Platform.new(p) === Gem::Platform.new(host_string) }
COMMON_BIN_PATH = File.expand_path("../bin/#{platform}/#{PLATFORMS[platform]}", File.dirname(__FILE__))

module Aws
  module Crt
    extend FFI::Library
    ffi_lib [COMMON_BIN_PATH, 'libaws-crt']
    attach_function :aws_crt_event_loop_group_new, [ :int ], :pointer
    attach_function :aws_crt_event_loop_group_destroy, [:pointer], :void
  end
end

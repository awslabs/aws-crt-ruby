# frozen_string_literal: true

# Maps OS name to crt binary name.
OS_BINARIES = {
  'darwin' => 'libaws-crt-ffi.dylib',
  'linux' => 'libaws-crt-ffi.so',
  'mingw32' => 'aws-crt-ffi.dll'
}.freeze

DEFAULT_BINARY = 'libaws-crt-ffi.so'

# @return [Gem::Platform] similar to Gem::Platform.local but will return
# host os/cpu for Jruby
def local_platform
  Gem::Platform.new(host_string)
end

# @return [Gem::Platform] return Gem::Platform for host os with target cpu
def target_platform(cpu)
  Gem::Platform.new(target_string(cpu))
end

# @return [String] return the file name for the CRT library for the platform
def crt_bin_name(platform)
  OS_BINARIES[platform.os] || DEFAULT_BINARY
end

# @return [String] return the directory of the CRT library for the platform
def crt_bin_dir(platform)
  File.expand_path("../../bin/#{platform.cpu}", File.dirname(__FILE__))
end

# @return [String] return the path to the CRT library for the platform
def crt_bin_path(platform)
  File.expand_path(crt_bin_name(platform), crt_bin_dir(platform))
end

# @return [String] generate a string that can be used with Gem::Platform
def host_string
  target_string(host_cpu)
end

# @return [String] generate a string that can be used with Gem::Platform
def target_string(cpu)
  "#{cpu}-#{host_os}"
end

# @return [String] host cpu, even on jruby
def host_cpu
  case RbConfig::CONFIG['host_cpu']
  when /86_64/
    'x86_64'
  when /86/
    'x86'
  else
    RbConfig::CONFIG['host_cpu']
  end
end

# @return [String] host os, even on jruby
def host_os
  case RbConfig::CONFIG['host_os']
  when /darwin/
    'darwin'
  when /linux/
    'linux'
  when /mingw|mswin/
    'mingw32'
  else
    RbConfig::CONFIG['host_os']
  end
end

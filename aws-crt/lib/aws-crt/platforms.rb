# Maps platform to crt binary name.  Needs to match what is used in the Rakefile for builds
PLATFORM_BINARIES = {
  'universal-darwin' => 'libaws-crt.dylib',
  'x86_64-linux' => 'libaws-crt.so',
  'universal-mingw32' => 'aws-crt.dll'
}.freeze

# @return [String] returns Gem::Platform style name for the current system
# similar to Gem::Platform.local but will return systems host os/cpu
# for Jruby
def local_platform
  PLATFORM_BINARIES.keys.find { |p| Gem::Platform.new(p) === Gem::Platform.new(host_string) }
end

# @return [String] return the path to the CRT library for the platform
def crt_bin_path(platform)
  File.expand_path("../../bin/#{platform}/#{PLATFORM_BINARIES[platform]}", File.dirname(__FILE__))
end

# @return [String] generate a string that be used with Gem::Platform
def host_string
  "#{host_cpu}-#{host_os}"
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

# frozen_string_literal: true

require 'etc'
require 'mkmf'
require 'fileutils'
require 'shellwords'
require_relative '../lib/aws-crt/platforms'

CMAKE_PATH = find_executable('cmake3') || find_executable('cmake')
abort 'Missing cmake' unless CMAKE_PATH
CMAKE = File.basename(CMAKE_PATH)

def run_cmd(args)
  # use shellwords.join() for printing, don't pass that string to system().
  # system() does better cross-platform when the args array is passed in.
  cmd_str = Shellwords.join(args)
  puts cmd_str
  system(*args) || raise("Error running: #{cmd_str}")
end

def find_file(name, search_dirs, base_dir)
  search_dirs.each do |search_dir|
    dir = File.expand_path(search_dir, base_dir)
    file_path = File.expand_path(name, dir)
    return file_path if File.exist?(file_path)
  end
  raise "Cannot find #{name}"
end

# Compile bin to expected location
def compile_bin(cpu)
  platform = target_platform(cpu)
  native_dir = File.expand_path('../aws-crt-ffi', File.dirname(__FILE__))
  tmp_dir = File.expand_path("../tmp/#{platform.cpu}", File.dirname(__FILE__))
  tmp_build_dir = File.expand_path('build', tmp_dir)

  # We need cmake to "install" aws-crt-ffi so that the binaries end up in a
  # predictable location. But cmake still adds subdirectories we don't want,
  # so we'll "install" under tmp, and manually copy to bin/ after that.
  tmp_install_dir = File.expand_path('install', tmp_dir)

  build_type = 'RelWithDebInfo'

  config_cmd = [
    CMAKE,
    "-H#{native_dir}",
    "-B#{tmp_build_dir}",
    "-DCMAKE_INSTALL_PREFIX=#{tmp_install_dir}",
    "-DCMAKE_BUILD_TYPE=#{build_type}",
    "-DBUILD_TESTING=OFF",
  ]

  # macOS can cross-compile for arm64 or x86_64 regardless of host's CPU type.
  config_cmd.append("-DCMAKE_OSX_ARCHITECTURES=#{platform.cpu}") if platform.os == 'darwin'

  build_cmd = [
    CMAKE,
    '--build', tmp_build_dir,
    '--target', 'install',
    '--config', build_type,
  ]

  # Build using all processors (cmake 3.12+ checks this ENV variable)
  ENV['CMAKE_BUILD_PARALLEL_LEVEL'] ||= Etc.nprocessors.to_s

  run_cmd(config_cmd)
  run_cmd(build_cmd)

  # Move file to bin/, instead of where cmake installed it under tmp/
  bin_dir = crt_bin_dir(platform)
  FileUtils.mkdir_p(bin_dir)
  bin_name = crt_bin_name(platform)
  search_dirs = [
    'bin', # windows
    'lib64', # some 64bit unix variants
    'lib', # some unix variants
  ]
  tmp_path = find_file(bin_name, search_dirs, tmp_install_dir)
  FileUtils.cp(tmp_path, bin_dir)
end

# frozen_string_literal: true

require 'mkmf'
require 'fileutils'
require 'shellwords'
require_relative '../lib/aws-crt/platforms'

CMAKE = find_executable('cmake3') || find_executable('cmake')
abort 'Missing cmake' unless CMAKE

def cmake_version
  version_cmd = Shellwords.join([CMAKE, '--version'])
  version_str = `#{version_cmd}`
  match = /(\d+)\.(\d+)\.(\d+)/.match(version_str)
  [match[1].to_i, match[2].to_i, match[3].to_i]
end

CMAKE_VERSION = cmake_version

# whether installed cmake supports --parallel build flag
def cmake_has_parallel_flag?
  (CMAKE_VERSION <=> [3, 12]) >= 0
end

def run_cmd(args)
  cmd = Shellwords.join(args)
  puts cmd
  system(cmd) || raise("Error running: #{cmd}")
end

def libcrypto_path
  path = ENV['LIBCRYPTO_PATH']
  File.absolute_path(path) if path
end

# Compile bin to expected location
def compile_bin
  platform = local_platform
  native_dir = File.expand_path('../native', File.dirname(__FILE__))
  build_dir = File.expand_path('../tmp', File.dirname(__FILE__))
  bin_dir = crt_bin_dir(platform)

  config_cmd = [CMAKE, native_dir, "-DBIN_DIR=#{bin_dir}"]
  config_cmd.append("-DCMAKE_PREFIX_PATH=#{libcrypto_path}") if libcrypto_path

  build_cmd = [CMAKE, '--build', build_dir, '--target', 'aws-crt']
  build_cmd.append('--parallel') if cmake_has_parallel_flag?

  # Need to run cmake from build dir.
  # Later versions of cmake (3.13+) can pass build dir via -B,
  # but min supported cmake (3.1) does not support this.
  FileUtils.mkdir_p(build_dir)
  FileUtils.chdir(build_dir) do
    run_cmd(config_cmd)
    run_cmd(build_cmd)
  end
end

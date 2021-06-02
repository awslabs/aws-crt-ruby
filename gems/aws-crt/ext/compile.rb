# frozen_string_literal: true

require 'mkmf'
require 'fileutils'
require 'shellwords'
require_relative '../lib/aws-crt/platforms'

CMAKE_PATH = find_executable('cmake3') || find_executable('cmake')
abort 'Missing cmake' unless CMAKE_PATH
CMAKE = File.basename(CMAKE_PATH)

def cmake_version
  version_str = `#{CMAKE} --version`
  match = /(\d+)\.(\d+)\.(\d+)/.match(version_str)
  [match[1].to_i, match[2].to_i, match[3].to_i]
end

CMAKE_VERSION = cmake_version

# whether installed cmake supports --parallel build flag
def cmake_has_parallel_flag?
  (CMAKE_VERSION <=> [3, 12]) >= 0
end

def run_cmd(args)
  # use shellwords.join() for printing, don't pass that string to system().
  # system() does better cross-platform when the args array is passed in.
  cmd_str = Shellwords.join(args)
  puts cmd_str
  system(*args) || raise("Error running: #{cmd_str}")
end

# Compile bin to expected location
def compile_bin
  platform = local_platform
  native_dir = File.expand_path('../native', File.dirname(__FILE__))
  build_dir = File.expand_path('../tmp', File.dirname(__FILE__))
  bin_dir = crt_bin_dir(platform)
  install_dir = File.expand_path(build_dir, 'install')

  config_cmd = [
    CMAKE, native_dir, "-DBIN_DIR=#{bin_dir}",
    "-DCMAKE_INSTALL_PREFIX=#{install_dir}"
  ]

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

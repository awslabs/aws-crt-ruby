# frozen_string_literal: true

require 'mkmf'
require 'fileutils'
require 'shellwords'
require_relative '../lib/aws-crt/platforms'

abort 'Missing cmake' unless find_executable 'cmake'

def cmake_version
  version_str = `cmake --version`
  match = /(\d+)\.(\d+)\.(\d+)/.match(version_str)
  [match[1].to_i, match[2].to_i, match[3].to_i]
end

# whether installed cmake supports --parallel build flag
def cmake_has_parallel_flag?
  (cmake_version <=> [3, 12]) >= 0
end

def run_cmd(args)
  system(*args) || raise("Error running: #{Shellwords.join(args)}")
end

# Compile bin to expected location
def compile_bin
  FileUtils.chdir(File.expand_path('..', File.dirname(__FILE__))) do
    platform = local_platform
    native_dir = File.expand_path('./native')
    build_dir = File.expand_path('./tmp')
    bin_dir = crt_bin_dir(platform)
    config_cmd = ['cmake', native_dir, "-DBIN_DIR=#{bin_dir}"]
    build_cmd = ['cmake', '--build', build_dir, '--target', 'aws-crt']
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
end

require 'fileutils'
require 'mkmf'
require_relative '../lib/aws-crt/platforms'

abort 'Missing cmake' unless find_executable 'cmake'

# Global variables that are expensive to calculate
module Const
  def self.cmake_version
    version_str = `cmake --version`
    match = /(\d+)\.(\d+)\.(\d+)/.match(version_str)
    [match[1].to_i, match[2].to_i, match[3].to_i]
  end

  CMAKE_VERSION = cmake_version

  # prefer ninja build system, which always builds in parallel
  NINJA_BUILD_SYSTEM = find_executable 'ninja'
end

# return whether installed cmake supports --parallel build flag
def cmake_has_parallel_flag?
  (Const::CMAKE_VERSION <=> [3, 12]) >= 0
end

# configure and build with cmake
def cmake_build(src_path, build_path, config_options)
  # Need to create build dir and run cmake from there.
  # Cmake 3.13+ lets you specify source and build dir without being in
  # those directories, but we support cmake 3.1+
  FileUtils.mkdir_p build_path
  Dir.chdir build_path do
    config_args = ['cmake', *config_options, src_path]
    config_args.insert(1, '-G', 'Ninja') if Const::NINJA_BUILD_SYSTEM
    config_cmd = config_args.join(' ')
    sh config_cmd

    build_cmd = 'cmake --build . --target install'
    build_cmd += ' --parallel' if cmake_has_parallel_flag?
    sh build_cmd
  end
end

# Path to native/
def crt_native_path
  File.expand_path('../native', File.dirname(__FILE__))
end

# Path for tmp build artifacts
def crt_tmp_path
  File.expand_path("../tmp/#{host_string}/#{RUBY_ENGINE}-#{RUBY_VERSION}",
                   File.dirname(__FILE__))
end

# Path for installing static lib dependencies of aws-crt
def crt_static_lib_install_path
  File.expand_path('install', crt_tmp_path)
end

# Compile a static lib dependency of aws-crt (ex: aws-c-common, s2n)
def crt_compile_static_lib(name)
  src_path = File.expand_path("aws-common-runtime/#{name}", crt_native_path)
  build_path = File.expand_path(name, crt_tmp_path)
  config_options = [
    "-DCMAKE_PREFIX_PATH=\"#{crt_static_lib_install_path}\"",
    "-DCMAKE_INSTALL_PREFIX=\"#{crt_static_lib_install_path}\"",
    '-DBUILD_SHARED_LIBS=OFF',
    '-DBUILD_TESTING=OFF'
  ]
  cmake_build(src_path, build_path, config_options)
end

# build/install static lib dependencies
def crt_compile_depencencies
  crt_compile_static_lib 'aws-c-common'
  unless Gem.win_platform? || local_platform.os == 'darwin'
    crt_compile_static_lib 's2n'
  end
  crt_compile_static_lib 'aws-c-io'
  crt_compile_static_lib 'aws-c-cal'
  crt_compile_static_lib 'aws-c-compression'
  crt_compile_static_lib 'aws-c-http'
  crt_compile_static_lib 'aws-c-auth'
end

# Compile the aws-crt shared lib to the bin/ directory
def crt_compile_bin
  crt_compile_depencencies

  src_path = crt_native_path
  build_path = File.expand_path('aws-crt', crt_tmp_path)
  install_path = crt_bin_dir(local_platform)
  config_options = [
    "-DCMAKE_PREFIX_PATH=\"#{crt_static_lib_install_path}\"",
    "-DCMAKE_INSTALL_PREFIX=\"#{install_path}\""
  ]
  cmake_build(src_path, build_path, config_options)
end

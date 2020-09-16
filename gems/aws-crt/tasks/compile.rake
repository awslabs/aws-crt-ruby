# frozen_string_literal: true

desc 'Compile CRT libraries'
task :compile do
  require 'fileutils'
  native_dir = File.expand_path('../native', File.dirname(__FILE__))
  build_dir = File.expand_path('build', native_dir)
  FileUtils.mkdir_p(build_dir)
  Dir.chdir(build_dir) do
    sh "cmake #{native_dir}"
    sh "cmake --build #{build_dir}"
  end
end

desc 'Move the compiled lib into bin'
task :bin => :compile do
  require_relative '../lib/aws-crt/platforms'
  platform = local_platform

  FileUtils.chdir('gems/aws-crt') do
    binary_name = crt_bin_name(platform)
    src_name = crt_build_out_path(platform)
    dest_name = "bin/#{platform.cpu}/#{binary_name}"
    FileUtils.mkdir_p("bin/#{platform.cpu}")
    FileUtils.cp(src_name, dest_name, verbose: true)
  end
end

task 'bin:all' do
  # TODO: generate or copy/download ect binaries for all platforms
end

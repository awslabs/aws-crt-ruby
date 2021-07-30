# frozen_string_literal: true

desc 'Compile CRT library and move to bin'
task :bin do
  require_relative '../ext/compile'
  compile_bin
end

desc 'Copies all binaries from the top level bin directory'
task 'bin:all' do
  FileUtils.cp_r('bin/', 'gems/aws-crt', verbose: true)
end

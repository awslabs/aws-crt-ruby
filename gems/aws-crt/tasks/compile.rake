# frozen_string_literal: true

desc 'Compile CRT library and move to bin'
task :bin do
  require_relative '../ext/compile'
  compile_bin
end

task 'bin:all' do
  # TODO: generate or copy/download ect binaries for all platforms
end

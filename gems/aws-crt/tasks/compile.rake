# frozen_string_literal: true

desc 'Compile CRT library and move to bin. Specify [cpu] to cross-compile.'
task :bin, [:cpu] do |_, args|
  require_relative '../lib/aws-crt/platforms'
  args.with_defaults(:cpu => host_cpu)

  require_relative '../ext/compile'
  compile_bin(args[:cpu])
end

desc 'Copies all binaries from the top level bin directory'
task 'bin:all' do
  FileUtils.cp_r('bin/', 'gems/aws-crt', verbose: true)
end

# frozen_string_literal: true

desc 'Compile CRT library and move to bin. Specify [cpu] to cross-compile.'
task :bin, [:cpu] do |_, args|
  require_relative '../lib/aws-crt/platforms'
  args.with_defaults(:cpu => host_cpu)

  require_relative '../ext/compile'
  compile_bin(args[:cpu])
end

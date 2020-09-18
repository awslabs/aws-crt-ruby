# frozen_string_literal: true

require 'rake/clean'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Dir.glob('**/*.rake').each do |task_file|
  load(task_file)
end

CLEAN.include 'gems/**/tmp'
CLEAN.include 'gems/**/pkg'
CLEAN.include 'gems/aws-crt/native/build'
CLEAN.include 'gems/aws-crt/bin'

desc 'Executes specs for a single gem, e.g. spec:aws-crt'
task 'spec:*' => :bin

rule(/spec:.+$/) do |task|
  spec_dir = "gems/#{task.name.split(':').last}/spec"
  sh("bundle exec rspec #{spec_dir}")
end

desc 'Execute all specs'
task :spec => :bin do
  Dir.glob('**/spec').tap do |spec_file_list|
    sh("bundle exec rspec #{spec_file_list.join(' ')}")
  end
end

RuboCop::RakeTask.new(:rubocop) do |t|
  config_file = File.join(File.dirname(__FILE__), '.rubocop.yml')
  t.options = ['-E', '-S', '-c', config_file]
end

task :release => %i[clean spec] do
  Rake::Task['gem:aws-crt'].invoke if ENV['GEM']
end

task 'gem:*'
rule(/gem:aws-crt-.+$/) do |task|
  require 'rubygems/package'
  gem_name = task.name.split(':').last
  puts "Building gem: #{gem_name}"
  FileUtils.chdir("gems/#{gem_name}") do
    spec = Gem::Specification.load("#{gem_name}.gemspec")
    gem_file = Gem::Package.build(spec)
    FileUtils.cp(gem_file, '../../pkg/')
  end
end

task 'package-all' do
  # aws-crt specific tasks
  Rake::Task['gem:aws-crt:pure-ruby'].invoke
  Rake::Task['gem:aws-crt:jruby'].invoke
  FileUtils.cp_r('gems/aws-crt/pkg/', './')

  # build all other gems
  gems = Dir.glob('gems/*').select { |f| File.directory? f }
            .map { |f| File.basename f }
            .reject { |f| f == 'aws-crt' }

  gems.each do |gem|
    Rake::Task["gem:#{gem}"].invoke
  end
end

# frozen_string_literal: true

require 'rake/clean'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Dir.glob('**/*.rake').each do |task_file|
  load(task_file)
end

CLEAN.include 'gems/**/tmp'
CLEAN.include 'gems/**/pkg'
CLEAN.include 'gems/aws-crt/bin'

desc 'Executes specs for a single gem, e.g. spec:aws-crt'
task 'spec:*' => :bin

rule(/spec:.+$/) do |task|
  spec_dir = "gems/#{task.name.split(':').last}/spec"
  sh("bundle exec rspec #{spec_dir}")
end

desc 'Execute all specs'
task :spec => :bin do
  Dir.glob('**/aws-crt*/spec').tap do |spec_file_list|
    sh("bundle exec rspec #{spec_file_list.join(' ')}")
  end
end

RuboCop::RakeTask.new(:rubocop) do |t|
  config_file = File.join(File.dirname(__FILE__), '.rubocop.yml')
  t.options = ['-E', '-S', '-c', config_file]
end

task :release => %i[clean spec] do
  Rake::Task['gem:aws-crt'].invoke if ENV['GEM']
  puts 'Release complete'
end

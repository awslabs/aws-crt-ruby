
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

desc 'Verify install/require for the higher level gems'
task 'verify-release:hll-gems' do
  puts "Verifying Higher level gems"
  gems = Dir.glob('gems/*').select { |f| File.directory? f }
         .map { |f| File.basename f }
         .reject { |f| f == 'aws-crt' }

  gems.each do |gem|
    version = File.read("gems/#{gem}/VERSION").strip
    gem_file = "#{gem}-#{version}.gem"
    puts "Installing #{gem_file}"
    res = Gem.install(gem_file, Gem::Requirement.default,
                      ignore_dependencies: true)
    $LOAD_PATH.unshift "#{res.first.full_gem_path}/lib"
  end

  gems.each do |gem|
    puts "Requiring #{gem}"
    require gem
  end
end

def install_and_require_crt_core(gem_file)
  puts "Installing #{gem_file}"
  res = Gem.install(gem_file)
  $LOAD_PATH.unshift "#{res.first.full_gem_path}/lib"
  puts "Installed #{gem_file}"
  puts "Requiring #{gem_file}"
  require 'aws-crt'
end

task 'verify-release:native' do
  require_relative '../gems/aws-crt/lib/aws-crt/platforms'
  crt_version = File.read('gems/aws-crt/VERSION').strip
  crt_gem = "aws-crt-#{crt_version}-#{local_platform}.gem"
  install_and_require_crt_core(crt_gem)

  Rake::Task['verify-release:hll-gems'].invoke
end

task 'verify-release:jruby' do
  crt_version = File.read('gems/aws-crt/VERSION').strip
  crt_gem = "aws-crt-#{crt_version}-universal-java.gem"
  install_and_require_crt_core(crt_gem)

  Rake::Task['verify-release:hll-gems'].invoke
end

task 'verify-release:pure-ruby' do
  crt_version = File.read('gems/aws-crt/VERSION').strip
  crt_gem = "aws-crt-#{crt_version}.gem"
  install_and_require_crt_core(crt_gem)

  Rake::Task['verify-release:hll-gems'].invoke
end

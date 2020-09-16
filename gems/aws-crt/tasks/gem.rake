# frozen_string_literal: true

desc 'Build the aws-crt gem for the local platform'
task 'gem:aws-crt:local' => [:bin] do
  require 'rubygems/package'
  require 'fileutils'
  require_relative '../lib/aws-crt/platforms'

  FileUtils.chdir('gems/aws-crt') do
    platform = local_platform
    binary_name = crt_bin_name(platform)

    FileUtils.mkdir_p('pkg/', verbose: true)

    # Load our gem specification.
    orig_spec = Gem::Specification.load('aws-crt.gemspec')
    spec = orig_spec.dup
    spec.platform = platform
    spec.files << "bin/#{platform.cpu}/#{binary_name}"

    # Build and move the gem to the pkg/ directory.
    gemname = Gem::Package.build(spec)
    File.join('pkg', File.basename(gemname)).tap do |gempath|
      FileUtils.mv(gemname, gempath, verbose: true)
    end
  end
end

desc 'Build the aws-crt gem for the local platform'
task 'gem:aws-crt' => 'gem:aws-crt:local'

desc 'Build the aws-crt gem for pure-ruby'
task 'gem:aws-crt:pure-ruby' => :clean do
  require 'rubygems/package'
  require 'fileutils'

  FileUtils.chdir('gems/aws-crt') do
    platform = Gem::Platform::RUBY
    FileUtils.mkdir_p('pkg', verbose: true)

    # Load our gem specification.
    orig_spec = Gem::Specification.load('aws-crt.gemspec')
    spec = orig_spec.dup
    spec.platform = platform
    spec.files += Dir['native/**/*']
    spec.extensions = FileList['ext/extconf.rb']

    # Build and move the gem to the pkg/ directory.
    gemname = Gem::Package.build(spec)
    File.join('pkg', File.basename(gemname)).tap do |gempath|
      FileUtils.mv(gemname, gempath, verbose: true)
    end
  end
end

desc 'Build the aws-crt gem for jruby, bundling all currently built platforms'
task 'gem:aws-crt:jruby' => 'bin:all' do
  require 'rubygems/package'
  require 'fileutils'

  FileUtils.chdir('gems/aws-crt') do
    platform = 'universal-java'

    FileUtils.mkdir_p('pkg', verbose: true)

    bin_platforms = Dir.glob('bin/**/*').reject { |f| File.directory? f }

    puts "Generating JRuby package with bin support for: #{bin_platforms}"

    # Load our gem specification.
    orig_spec = Gem::Specification.load('aws-crt.gemspec')
    spec = orig_spec.dup
    spec.platform = platform
    spec.files += Dir['bin/**/*'].reject { |f| File.directory? f }

    # Build and move the gem to the pkg/ directory.
    gemname = Gem::Package.build(spec)
    File.join('pkg', File.basename(gemname)).tap do |gempath|
      FileUtils.mv(gemname, gempath, verbose: true)
    end
  end
end

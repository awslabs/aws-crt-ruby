require 'rake/extensiontask'

# Generate native gems that bundle the extensions
# Allows us to run: `rake gem` to build pure ruby gem
# and `rake native gem` to build native gem (builds multiple versions)
# Also allows `rake java gem` to build jruby extensions
spec = Gem::Specification.new do |spec|
  spec.name = 'aws-crt-ruby'
  spec.version = File.read(File.expand_path('../VERSION', __FILE__)).strip
  spec.summary = 'AWS SDK for Ruby - Common Run Time'
  spec.author = 'Amazon Web Services'
  spec.homepage = 'https://github.com/awslabs/aws-crt-ruby'
  spec.license = 'Apache-2.0'
  spec.require_paths = ['lib']
  spec.files = ['VERSION']
  spec.files += Dir['lib/**/*.rb']
  spec.platform = Gem::Platform::RUBY
  spec.extensions = FileList['ext/**/extconf.rb']
end

# default gem packing task
Gem::PackageTask.new(spec) do |pkg|
end

# This gives `rake compile` as a task which can then hook into other tasks
# such as tests
Rake::ExtensionTask.new('aws_crt_ruby', spec)  do |ext|
  ext.lib_dir = 'lib/aws-crt-ruby'
end

# If we had java (w/ JNI) we would add this
# Rake::JavaExtensionTask.new('aws-crt-ruby')

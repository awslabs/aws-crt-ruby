# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'aws-crt-auth'
  spec.version = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.summary = 'AWS SDK for Ruby - Common Run Time client-side authentication'
  spec.description = 'AWS client-side authentication: standard credentials providers and signing'
  spec.author = 'Amazon Web Services'
  spec.homepage = 'https://github.com/awslabs/aws-crt-ruby'
  spec.license = 'Apache-2.0'
  spec.require_paths = ['lib']
  spec.files = ['VERSION']
  spec.files += Dir['lib/**/*.rb']
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.4'
  spec.add_dependency 'aws-crt'
  spec.add_development_dependency 'rspec'
end

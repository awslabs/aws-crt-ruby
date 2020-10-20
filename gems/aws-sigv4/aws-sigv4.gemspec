# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'aws-crt-signer'
  spec.version = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.summary = 'AWS SDK for Ruby - Common Runtime (CRT) based Signer'
  spec.description = 'Amazon Web Services signing library. Generates signatures for HTTP requests'
  spec.author = 'Amazon Web Services'
  spec.homepage = 'https://github.com/awslabs/aws-crt-ruby'
  spec.license = 'Apache-2.0'
  spec.require_paths = ['lib']
  spec.files = ['VERSION']
  spec.files += Dir['lib/**/*.rb']
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.5'
  spec.add_dependency 'aws-crt-auth'
  spec.add_dependency('aws-eventstream', '~> 1', '>= 1.0.2') # For signing event stream events
  spec.add_development_dependency 'rspec'
end

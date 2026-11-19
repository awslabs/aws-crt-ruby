## AWS Common Runtime for Ruby
[![aws-crt Gem Version](https://badge.fury.io/rb/aws-crt.svg)](https://badge.fury.io/rb/aws-crt)
[![Build Status](https://github.com/awslabs/aws-crt-ruby/workflows/CI/badge.svg)](https://github.com/awslabs/aws-crt-ruby/actions)
[![Github forks](https://img.shields.io/github/forks/awslabs/aws-crt-ruby.svg)](https://github.com/awslabs/aws-crt-ruby/network)
[![Github stars](https://img.shields.io/github/stars/awslabs/aws-crt-ruby.svg)](https://github.com/awslabs/aws-crt-ruby/stargazers)

The AWS Common Runtime (CRT) for Ruby provides Ruby bindings to native CRT libraries. It includes accelerated CRC32, CRC32C, and CRC64NVME checksums, and AWS request signing with SigV4, SigV4a, and SigV4 for S3 Express.

## Links of Interest
* [AWS Common Runtime](https://docs.aws.amazon.com/sdkref/latest/guide/common-runtime.html)

## Requirements

Ruby 2.7 or later.

## Installation
AWS CRT bindings are available from RubyGems as the `aws-crt` gem.

Install the gem directly:

```console
gem install aws-crt
```

Or add it to your Gemfile:

```ruby
gem 'aws-crt', '~> 0'
```

When installed alongside the AWS SDK for Ruby, `aws-crt` provides native CRC32C and CRC64NVME checksum implementations.

## Versioning

This project uses [semantic versioning](http://semver.org/). You can safely
express a dependency on a major version and expect all minor and patch versions
to be backwards compatible.

A CHANGELOG can be found at each gem's root path (i.e. `aws-crt` can be found
at `gems/aws-crt/CHANGELOG.md`). The CHANGELOG is also accessible via the
RubyGems.org page under "LINKS" section.

## Maintenance and support for SDK major versions

For information about maintenance and support for SDK major versions and their underlying dependencies, see the following in the [AWS SDKs and Tools Reference Guide](https://docs.aws.amazon.com/sdkref/latest/guide/overview.html):

* [AWS SDKs and Tools Maintenance Policy](https://docs.aws.amazon.com/sdkref/latest/guide/maint-policy.html)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.


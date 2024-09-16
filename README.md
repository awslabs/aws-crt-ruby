## AWS Common Runtime for Ruby
[![aws-crt Gem Version](https://badge.fury.io/rb/aws-crt.svg)](https://badge.fury.io/rb/aws-crt)
[![Build Status](https://github.com/awslabs/aws-crt-ruby/workflows/CI/badge.svg)](https://github.com/awslabs/aws-crt-ruby/actions)
[![Github forks](https://img.shields.io/github/forks/awslabs/aws-crt-ruby.svg)](https://github.com/awslabs/aws-crt-ruby/network)
[![Github stars](https://img.shields.io/github/stars/awslabs/aws-crt-ruby.svg)](https://github.com/awslabs/aws-crt-ruby/stargazers)

## Links of Interest
* [AWS Common Run Time](https://docs.aws.amazon.com/sdkref/latest/guide/common-runtime.html)

## Installation 
AWS CRT bindings are available from RubyGems as the `aws-crt` gem.

```ruby
gem 'aws-sdk-s3', '~> 1'
gem 'aws-crt', '~> 0'
```

`aws-crt` currently provides fast checksum implementations for CRC32c and CRC64.

## Versioning

This project uses [semantic versioning](http://semver.org/). You can safely
express a dependency on a major version and expect all minor and patch versions
to be backwards compatible.

A CHANGELOG can be found at each gem's root path (i.e. `aws-crt` can be found
at `gems/aws-crt/CHANGELOG.md`). The CHANGELOG is also accessible via the
RubyGems.org page under "LINKS" section.

## Maintenance and support for SDK major versions

For information about maintenance and support for SDK major versions and their underlying dependencies, see the following in the [AWS SDKs and Tools Shared Configuration and Credentials Reference Guide](https://docs.aws.amazon.com/credref/latest/refdocs/overview.html):

* [AWS SDKs and Tools Maintenance Policy](https://docs.aws.amazon.com/credref/latest/refdocs/maint-policy.html)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.


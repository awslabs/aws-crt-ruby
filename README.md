## AWS Common Runtime for Ruby
[![aws-crt Gem Version](https://badge.fury.io/rb/aws-crt.svg)](https://badge.fury.io/rb/aws-crt)
[![Build Status](https://github.com/awslabs/aws-crt-ruby/workflows/CI/badge.svg)](https://github.com/awslabs/aws-crt-ruby/actions)
[![Github forks](https://img.shields.io/github/forks/awslabs/aws-crt-ruby.svg)](https://github.com/awslabs/aws-crt-ruby/network)
[![Github stars](https://img.shields.io/github/stars/awslabs/aws-crt-ruby.svg)](https://github.com/awslabs/aws-crt-ruby/stargazers)

## Links of Interest
* [AWS Common Run Time](https://docs.aws.amazon.com/sdkref/latest/guide/common-runtime.html)

## Installation 
AWS CRT bindings are in developer preview and are available from RubyGems as the `aws-crt` gem.  You can install them by adding the `aws-crt`
gem to your Gemfile.

[Sigv4a](https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html)
is an extension to Sigv4 that allows signatures that are valid in more than one region.
Sigv4a is required to use some services/operations such as
[S3 Multi-Region Access Points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiRegionAccessPoints.html).
Currently sigv4a requires the [aws-crt](https://rubygems.org/gems/aws-crt/) gem and a version of the 
[aws-sigv4](https://rubygems.org/gems/aws-sigv4/versions/1.4.1.crt) gem built on top of aws-crt - 
these versions end with "-crt".  To install and use a CRT enabled version, we recommend pinning the
specific version of `aws-sigv4` in your Gemfile (this will also install the `aws-crt` gem):

```ruby
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sigv4', '1.4.1.crt'
```

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


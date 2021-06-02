# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./gems/aws-sigv4/lib', __dir__)

# use the local version of aws-crt libs
$LOAD_PATH.unshift File.expand_path('./gems/aws-crt/lib', __dir__)
$LOAD_PATH.unshift File.expand_path('./gems/aws-crt-auth/lib', __dir__)

require 'aws-sigv4'
require 'benchmark'

type = 'CRT'
n_sigs = 10_000

credentials = {
  access_key_id: 'akid',
  secret_access_key: 'secret'
}
options = {
  service: 'SERVICE',
  region: 'REGION',
  signing_algorithm: :sigv4a,
  credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(credentials),
  unsigned_headers: ['Content-Length']
}

t1 = Time.now
Benchmark.bmbm do |bm|
  bm.report('CRT') do
    n_sigs.times do
      Aws::Sigv4::Signer.new(options).sign_request(
        http_method: 'PUT',
        url: 'https://domain.com',
        headers: {
          'Foo' => 'foo',
          'Bar' => 'bar  bar',
          'Bar2' => '"bar bar"',
          'Content-Length' => 9,
          'X-Amz-Date' => '20120101T112233Z'
        },
        body: StringIO.new('http-body')
      )
    end
  end
end
t2 = Time.now
puts "#{type}, #{n_sigs}, #{t2 - t1}, #{(t2 - t1) / n_sigs * 1000.0 * 1000}"

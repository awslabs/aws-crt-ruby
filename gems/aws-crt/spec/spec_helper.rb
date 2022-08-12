# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'aws-crt'
require 'rspec'

RSpec.configure do |config|
  config.after(:all) do
    check_for_clean_shutdown
  end
end

# Return whether ObjectSpace.garbage_collect
# can be relied on to immediately clean up everything possible
def garbage_collect_is_immediate?
  RUBY_ENGINE == 'ruby'
end

# Wait for resources with worker threads (ex: EventLoopGroup, HostResolver)
# to finish their async shutdowns. If this fails, there is a reference
# somewhere keeping these resources alive.
def check_for_clean_shutdown
  ObjectSpace.garbage_collect

  if Aws::Crt::Native.mem_bytes.positive? ||
     Aws::Crt::Native.mem_count.positive?
    raise 'Possible memory leak, mem_bytes: ' \
          "#{Aws::Crt::Native.mem_bytes} and " \
          "mem_count: #{Aws::Crt::Native.mem_count}"
  end
  # TODO: This currently fails
  # Aws::Crt::Native.thread_join_all(1000000000)
end

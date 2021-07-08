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

  puts "Calling native cleanup...."
  Aws::Crt::Native.clean_up
end

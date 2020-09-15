# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'aws-crt'

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

  Aws::Crt.call { Aws::Crt::Native.global_thread_creator_shutdown_wait_for(10) }
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'aws-crt'

# Return whether ObjectSpace.garbage_collect
# can be relied on to immediately clean up everything possible
def garbage_collect_is_immediate?
  RUBY_ENGINE == 'ruby'
end

def check_for_clean_shutdown
  ObjectSpace.garbage_collect

  # Wait for resources with worker threads (ex: EventLoopGroup and HostResolver)
  # to finish their async shutdowns
  Aws::Crt.call { Aws::Crt::Native.global_thread_creator_shutdown_wait_for(10) }
end

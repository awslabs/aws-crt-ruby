$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'aws-crt'

def check_for_clean_shutdown
  ObjectSpace.garbage_collect

  # Wait for resources with worker threads (ex: EventLoopGroup and HostResolver)
  # to finish their async shutdowns
  Aws::Crt.call { Aws::Crt::Native.global_thread_creator_shutdown_wait_for(10) }
end

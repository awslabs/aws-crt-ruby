# frozen_string_literal: true

module Aws
  module Crt
    # High level Ruby abstractions for CRT IO functionality
    module IO
      # A collection of event-loops.
      # An event-loop is a thread for doing async work, such as I/O.
      # Classes that need to do async work will ask the EventLoopGroup
      # for an event-loop to use.
      class EventLoopGroup
        def initialize(max_threads = nil)
          unless max_threads.nil? ||
                 (max_threads.is_a?(Integer) && max_threads.positive?)
            raise ArgumentError, 'max_threads must be nil or positive Integer'
          end

          # Ruby uses nil to request default values, native code uses 0
          max_threads = 0 if max_threads.nil?

          @native = Aws::Crt.call do
            Aws::Crt::Native.event_loop_group_new(max_threads)
          end

          ObjectSpace.define_finalizer(self, self.class.finalize(@native))
        end

        # Release native object.
        # Note that the native object has its own refcount, and will remain
        # alive until all other native resources are done using it.
        def self.finalize(native)
          proc do
            Aws::Crt::Native.event_loop_group_release(native)
          end
        end
      end
    end
  end
end

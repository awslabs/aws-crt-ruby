# frozen_string_literal: true

module Aws
  module Crt
    # High level Ruby abstractions for CRT IO functionality
    module IO
      # Options for an EventLoopGroup
      class EventLoopGroupOptions
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(
          :event_loop_group_options_release
        )

        def initialize(max_threads = nil)
          unless max_threads.nil? ||
                 (max_threads.is_a?(Integer) && max_threads.positive?)
            raise ArgumentError, 'max_threads must be nil or positive Integer'
          end

          # Ruby uses nil to request default values, native code uses 0
          max_threads = 0 if max_threads.nil?

          manage_native do
            Aws::Crt::Native.event_loop_group_options_new
          end

          Aws::Crt::Native.event_loop_group_options_set_max_threads(@native,
                                                                    max_threads)
        end
      end

      # A collection of event-loops.
      # An event-loop is a thread for doing async work, such as I/O.
      # Classes that need to do async work will ask the EventLoopGroup
      # for an event-loop to use.
      class EventLoopGroup
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:event_loop_group_release)

        def initialize(max_threads = nil)
          @options = EventLoopGroupOptions.new(max_threads)

          manage_native do
            Aws::Crt::Native.event_loop_group_new(@options.native)
          end
          Aws::Crt::Native.event_loop_group_acquire(@native)
        end
      end
    end
  end
end

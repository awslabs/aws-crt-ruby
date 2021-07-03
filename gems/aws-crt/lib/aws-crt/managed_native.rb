# frozen_string_literal: true

module Aws
  module Crt
    # A mixin module for generic managed native functionality
    # Example:
    #
    #   class C
    #     include Aws::Crt::ManagedNative
    #     native_destroy Aws::Crt::Native.method(:test_struct_destroy)
    #
    #     def initialize
    #       manage_native { Aws::Crt::Native::test_struct_new() }
    #     end
    #
    #     def use_native
    #       Aws::Crt::Native::test_method(native) #use that getter for native
    #     end
    #   end
    module ManagedNative
      def self.included(sub_class)
        sub_class.extend(ClassMethods)
      end

      # expects a block that returns a :pointer to the native resource
      # that this class manages
      def manage_native(&block)
        # check that a destructor has been registered
        unless self.class.instance_variable_get('@destructor')
          raise 'No native destructor registered.  use native_destroy to ' \
                'set the method used to cleanup the native object this ' \
                'class manages.'
        end
        native = block.call
        @native = FFI::AutoPointer.new(native, self.class.method(:on_release))
      end

      # @param [Boolean] safe (true) - raise an exception if the native object
      #   is not set (has been freed or never created)
      # @return [FFI:Pointer]
      def native(safe: true)
        raise '@native is unset or has been freed.' if safe && !@native

        @native
      end

      # @return [Boolean]
      def native_set?
        !!@native
      end

      # Immediately release this instance's attachment to the underlying
      # resources, without waiting for the garbage collector.
      # Note that underlying resources will remain alive until nothing
      # else is using them.
      def release
        return unless @native

        @native.free
        @native = nil
      end

      # ClassMethods for ManagedNative
      module ClassMethods
        # Register the method used to cleanup the native object this class
        # manages.  Must be a method, use object.method(:method_name).
        #
        # Example:
        #  native_destroy Aws::Crt::Native.method(:test_release)
        def native_destroy(destructor)
          unless destructor.is_a?(Method)
            raise ArgumentError,
                  'destructor must be a Method. ' \
                  'Use object.method(:method_name)'
          end
          @destructor = destructor
        end

        # Do not call directly
        # method passed to FFI Autopointer to call the destructor
        def on_release(native)
          @destructor.call(native)
        end
      end
    end
  end
end

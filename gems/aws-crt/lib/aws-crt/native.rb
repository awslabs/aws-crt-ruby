# frozen_string_literal: true

require 'ffi'
module Aws
  module Crt
    # FFI Bindings to native CRT functions
    module Native
      extend FFI::Library

      ffi_lib [crt_bin_path(local_platform), 'libaws-crt']

      # aws_byte_cursor binding
      class ByteCursor < FFI::Struct
        layout :len, :size_t,
               :ptr, :pointer

        def to_s
          return unless (self[:len]).positive? && !(self[:ptr]).null?

          self[:ptr].get_string(0, self[:len])
        end
      end

      # Core API
      attach_function :init, :aws_crt_init, [], :void
      attach_function :last_error, :aws_crt_last_error, [], :int
      attach_function :error_str, :aws_crt_error_str, [:int], :string
      attach_function :error_name, :aws_crt_error_name, [:int], :string
      attach_function :error_debug_str, :aws_crt_error_debug_str, [:int], :string
      attach_function :reset_error, :aws_crt_reset_error, [], :void

      # This MUST follow definitions of core error functions since it relies on them
      # And error functions should NOT be wrapped.
      #
      # Overridden for three purposes.
      #
      # 1. Allows us to only supply the aws_crt C name, and converts it removes
      #     the aws_crt.
      # 2. Wraps the call in an error-raise checker.
      # 3. Creates a bang method that does not do automatic error checking.
      def self.attach_function(c_name, params, returns, options = {})
        ruby_name = c_name.to_s.sub(/aws_crt_/, '').to_sym
        bang_name = "#{ruby_name}!"

        super(ruby_name, c_name, params, returns, options)
        alias_method(bang_name, ruby_name)

        define_method(ruby_name) do |*args, &block|
          res = public_send(bang_name, *args, &block)
          # functions that return void cannot fail
          return unless res

          # for functions that return int, non-zero indicates failure
          Errors.raise_last_error if res.is_a?(Integer) && res != 0

          # for functions that return pointer, NULL indicates failure
          Errors.raise_last_error if res.is_a?(FFI::Pointer) && res.null?

          res
        end

        module_function ruby_name
        module_function bang_name
      end

      attach_function :aws_crt_global_thread_creator_shutdown_wait_for, [:uint32], :int

      # IO API
      attach_function :aws_crt_event_loop_group_new, [:uint16], :pointer
      attach_function :aws_crt_event_loop_group_release, [:pointer], :void

      # Auth API
      attach_function :aws_crt_credentials_new, %i[string string string uint64], :pointer
      attach_function :aws_crt_credentials_release, [:pointer], :void
      attach_function :aws_crt_credentials_get_access_key_id, [:pointer], ByteCursor.by_value
      attach_function :aws_crt_credentials_get_secret_access_key, [:pointer], ByteCursor.by_value
      attach_function :aws_crt_credentials_get_session_token, [:pointer], ByteCursor.by_value
      attach_function :aws_crt_credentials_get_expiration_timepoint_seconds, [:pointer], :uint64

      # Internal testing API
      attach_function :aws_crt_test_error, [:int], :int
      attach_function :aws_crt_test_pointer_error, [], :pointer
    end
  end
end

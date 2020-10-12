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

          self[:ptr].read_string(self[:len])
        end
      end

      # Extends FFI::attach_function
      #
      # 1. Allows us to only supply the aws_crt C name and removes
      #     the aws_crt.
      # 2. Wraps the call in an error-raise checker (unless options[:raise]
      #   = false)
      # 3. Creates a bang method that does not do automatic error checking.
      def self.attach_function(c_name, params, returns, options = {})
        ruby_name = c_name.to_s.sub(/aws_crt_/, '').to_sym
        raise_errors = options.fetch(:raise, true)
        options.delete(:raise)
        unless raise_errors
          return super(ruby_name, c_name, params, returns, options)
        end

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

      # Core API
      attach_function :aws_crt_init, [], :void, raise: false
      attach_function :aws_crt_last_error, [], :int, raise: false
      attach_function :aws_crt_error_str, [:int], :string, raise: false
      attach_function :aws_crt_error_name, [:int], :string, raise: false
      attach_function :aws_crt_error_debug_str, [:int], :string, raise: false
      attach_function :aws_crt_reset_error, [], :void, raise: false

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

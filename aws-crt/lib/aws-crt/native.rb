require 'ffi'

module Aws::Crt
  module Native
    extend FFI::Library

    ffi_lib [crt_bin_path(local_platform), 'libaws-crt']

    # Core API
    attach_function :init, :aws_crt_init, [], :void
    attach_function :last_error, :aws_last_error, [], :int
    attach_function :error_str, :aws_error_str, [:int], :string
    attach_function :error_name, :aws_error_name, [:int], :string
    attach_function :error_lib_name, :aws_error_lib_name, [:int], :string
    attach_function :error_debug_str, :aws_error_debug_str, [:int], :string
    attach_function :reset_error, :aws_reset_error, [], :void
    # IO API
    attach_function :event_loop_group_new, :aws_crt_event_loop_group_new, [:uint16], :pointer
    attach_function :event_loop_group_destroy, :aws_crt_event_loop_group_destroy, [:pointer], :void
    # Internal testing API
    attach_function :test_error, :aws_crt_test_error, [:int], :int
    attach_function :test_pointer_error, :aws_crt_test_pointer_error, [], :pointer
  end
end

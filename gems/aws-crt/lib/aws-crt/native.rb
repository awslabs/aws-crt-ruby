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

      # Managed PropertyList Struct (for outputs)
      class PropertyList < FFI::ManagedStruct
        layout :len, :size_t,
               :names, :pointer,
               :values, :pointer

        def props
          return nil if to_ptr.null?

          return {} unless (self[:len]).positive?

          out = {}
          names_p = self[:names].get_array_of_pointer(0, self[:len])
          values_p = self[:values].get_array_of_pointer(0, self[:len])
          names_p.zip(values_p).each do |name_p, value_p|
            out[name_p.read_string.dup] = value_p.read_string.dup
          end
          out
        end

        def self.release(ptr)
          Aws::Crt::Native.aws_crt_property_list_release(ptr)
        end
      end

      # Given a ruby hash (string -> string), return two native arrays:
      # char** (:pointer) AND a list of all of the FFI::MemoryPointers
      # that must be kept around to avoid GC
      def self.hash_to_native_arrays(hash)
        key_array, keys_p = array_to_native(hash.keys)
        value_array, values_p = array_to_native(hash.values)
        [key_array, value_array, keys_p + values_p]
      end

      # Given a ruby array of strings, return a native array: char** and
      # the FFI::MemoryPointers (these need to be pined for the length the
      # native memory will be used to avoid GC)
      def self.array_to_native(array)
        native = FFI::MemoryPointer.new(:pointer, array.size)
        pointers = array.map do |s|
          FFI::MemoryPointer.from_string(s.to_s)
        end
        native.write_array_of_pointer(pointers)
        [native, pointers]
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

      enum :signing_algorithm, [:sigv4, :sigv4a]
      enum :signature_type, %i[http_request_headers http_request_query_params
                               http_request_chunk http_request_event]
      enum :signed_body_header_type, %i[sbht_none sbht_content_sha256]
      callback :should_sign_header_fn, [ByteCursor.by_ref, :pointer], :bool
      attach_function :aws_crt_signing_config_new, %i[signing_algorithm signature_type string string string uint64 pointer signed_body_header_type should_sign_header_fn bool bool bool uint64], :pointer
      attach_function :aws_crt_signing_config_release, [:pointer], :void
      attach_function :aws_crt_signing_config_is_signing_synchronous, [:pointer], :bool, raise: false

      attach_function :aws_crt_signable_new, [], :pointer
      attach_function :aws_crt_signable_release, [:pointer], :void
      attach_function :aws_crt_signable_set_property, %i[pointer string string], :int
      attach_function :aws_crt_signable_get_property, %i[pointer string], :string, raise: false
      attach_function :aws_crt_signable_append_property_list, %i[pointer string string string], :int
      attach_function :aws_crt_signable_set_property_list, %i[pointer string size_t pointer pointer], :int

      callback :signing_complete_fn, %i[pointer int string], :void
      attach_function :aws_crt_sign_request, %i[pointer pointer string signing_complete_fn], :int
      attach_function :aws_crt_verify_sigv4a_signing, %i[pointer pointer string string string string], :int

      attach_function :aws_crt_signing_result_get_property, %i[pointer string], :string, raise: false
      attach_function :aws_crt_signing_result_get_property_list, %i[pointer string], PropertyList.by_ref, raise: false
      attach_function :aws_crt_property_list_release, %i[pointer], :void

      # Internal testing API
      attach_function :aws_crt_test_error, [:int], :int
      attach_function :aws_crt_test_pointer_error, [], :pointer
    end
  end
end

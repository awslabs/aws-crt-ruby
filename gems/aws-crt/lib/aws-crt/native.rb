# frozen_string_literal: true

require 'ffi'
module Aws
  module Crt
    # FFI Bindings to native CRT functions
    module Native
      extend FFI::Library

      ffi_lib [crt_bin_path(local_platform), 'libaws-crt-ffi']

      # aws_byte_cursor binding
      class ByteCursor < FFI::Struct
        layout :len, :size_t,
               :ptr, :pointer

        def to_s
          return unless (self[:len]).positive? && !(self[:ptr]).null?

          self[:ptr].read_string(self[:len])
        end
      end

      # Warning, when used as an output structure
      # the memory in ptr needs to be manually destructed!
      class CrtBuf < FFI::Struct
        layout :ptr, :pointer,
               :len, :size_t

        def to_blob
          return unless (self[:len]).positive? && !(self[:ptr]).null?

          self[:ptr].read_array_of_char(self[:len])
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
      attach_function :aws_crt_clean_up, [], :void
      attach_function :aws_crt_last_error, [], :int, raise: false
      attach_function :aws_crt_error_str, [:int], :string, raise: false
      attach_function :aws_crt_error_name, [:int], :string, raise: false
      attach_function :aws_crt_error_debug_str, [:int], :string, raise: false
      attach_function :aws_crt_reset_error, [], :void, raise: false

      # Core Memory Management
      attach_function :aws_crt_mem_release, [:pointer], :void, raise: false

      typedef :pointer, :blob

      # IO API
      typedef :pointer, :event_loop_group_options_ptr
      attach_function :aws_crt_event_loop_group_options_new, [], :event_loop_group_options_ptr
      attach_function :aws_crt_event_loop_group_options_release, [:event_loop_group_options_ptr], :void
      attach_function :aws_crt_event_loop_group_options_set_max_threads, %i[event_loop_group_options_ptr uint16], :void

      typedef :pointer, :event_loop_group_ptr
      attach_function :aws_crt_event_loop_group_new, [:event_loop_group_options_ptr], :pointer
      attach_function :aws_crt_event_loop_group_acquire, [:event_loop_group_ptr], :event_loop_group_ptr
      attach_function :aws_crt_event_loop_group_release, [:event_loop_group_ptr], :void

      # HTTP API
      typedef :pointer, :headers_ptr
      attach_function :aws_crt_http_headers_new_from_blob, %i[blob size_t], :headers_ptr
      attach_function :aws_crt_http_headers_to_blob, [:headers_ptr, CrtBuf], :void
      attach_function :aws_crt_http_headers_release, [:headers_ptr], :void

      typedef :pointer, :http_message_ptr
      attach_function :aws_crt_http_message_new_from_blob, %i[blob size_t], :http_message_ptr
      attach_function :aws_crt_http_message_to_blob, [:http_message_ptr, CrtBuf], :void
      attach_function :aws_crt_http_message_release, [:http_message_ptr], :void

      # Auth API
      typedef :pointer, :credentials_options_ptr
      attach_function :aws_crt_credentials_options_new, [], :credentials_options_ptr
      attach_function :aws_crt_credentials_options_release, [:credentials_options_ptr], :void
      attach_function :aws_crt_credentials_options_set_access_key_id, %i[credentials_options_ptr string size_t], :void
      attach_function :aws_crt_credentials_options_set_secret_access_key, %i[credentials_options_ptr string size_t], :void
      attach_function :aws_crt_credentials_options_set_session_token, %i[credentials_options_ptr string size_t], :void
      attach_function :aws_crt_credentials_options_set_expiration_timepoint_seconds, %i[credentials_options_ptr uint64], :void

      typedef :pointer, :credentials_ptr
      attach_function :aws_crt_credentials_new, [:credentials_options_ptr], :credentials_ptr
      attach_function :aws_crt_credentials_acquire, [:credentials_ptr], :credentials_ptr
      attach_function :aws_crt_credentials_release, [:credentials_ptr], :void

      typedef :pointer, :credentials_provider_ptr
      attach_function :aws_crt_credentials_provider_acquire, [:credentials_provider_ptr], :credentials_provider_ptr
      attach_function :aws_crt_credentials_provider_release, [:credentials_provider_ptr], :void

      typedef :pointer, :static_cred_provider_options_ptr
      attach_function :aws_crt_credentials_provider_static_options_new, [], :static_cred_provider_options_ptr
      attach_function :aws_crt_credentials_provider_static_options_release, [:static_cred_provider_options_ptr], :void
      attach_function :aws_crt_credentials_provider_static_options_set_access_key_id, %i[static_cred_provider_options_ptr string size_t], :void
      attach_function :aws_crt_credentials_provider_static_options_set_secret_access_key, %i[static_cred_provider_options_ptr string size_t], :void
      attach_function :aws_crt_credentials_provider_static_options_set_session_token, %i[static_cred_provider_options_ptr string size_t], :void

      attach_function :aws_crt_credentials_provider_static_new, [:static_cred_provider_options_ptr], :credentials_provider_ptr



      enum :signing_algorithm, %i[sigv4 sigv4a]
      enum :signature_type, %i[
        http_request_headers http_request_query_params
        http_request_chunk http_request_event
        canonical_request_headers canonical_request_query_params
      ]
      enum :signed_body_header_type, %i[sbht_none sbht_content_sha256]

      typedef :pointer, :signing_config_ptr
      attach_function :aws_crt_signing_config_aws_new, [], :signing_config_ptr
      attach_function :aws_crt_signing_config_aws_release, [:signing_config_ptr], :void


      # callback :should_sign_header_fn, [ByteCursor.by_ref, :pointer], :bool
      # attach_function :aws_crt_signing_config_new, %i[signing_algorithm signature_type string string string uint64 pointer signed_body_header_type should_sign_header_fn bool bool bool uint64], :pointer
      # attach_function :aws_crt_signing_config_release, [:pointer], :void
      # attach_function :aws_crt_signing_config_is_signing_synchronous, [:pointer], :bool, raise: false
      #
      # attach_function :aws_crt_signable_new, [], :pointer
      # attach_function :aws_crt_signable_release, [:pointer], :void
      # attach_function :aws_crt_signable_set_property, %i[pointer string string], :int
      # attach_function :aws_crt_signable_get_property, %i[pointer string], :string, raise: false
      # attach_function :aws_crt_signable_append_property_list, %i[pointer string string string], :int
      # attach_function :aws_crt_signable_set_property_list, %i[pointer string size_t pointer pointer], :int
      #
      # callback :signing_complete_fn, %i[pointer int pointer], :void
      # attach_function :aws_crt_sign_request_synchronous, %i[pointer pointer signing_complete_fn], :int
      # attach_function :aws_crt_verify_sigv4a_signing, %i[pointer pointer string string string string], :int
      #
      # attach_function :aws_crt_signing_result_get_property, %i[pointer string], :string, raise: false
      # attach_function :aws_crt_signing_result_get_property_list, %i[pointer string], PropertyList.by_ref, raise: false
      # attach_function :aws_crt_property_list_release, %i[pointer], :void

      # Internal testing API
      attach_function :aws_crt_test_error, [:int], :int
    end
  end
end

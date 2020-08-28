require 'ffi'

# Maps platform to crt binary name.  Needs to match what is used in the Rakefile for builds
PLATFORMS = {
  "universal-darwin" => 'libaws-crt.dylib'
}.freeze

def host_string
  "#{host_cpu}-#{host_os}"
end

# @return [String] host cpu, even on jruby
def host_cpu
  case RbConfig::CONFIG["host_cpu"]
  when /86_64/
    "x86_64"
  when /86/
    "x86"
  else
    RbConfig::CONFIG["host_cpu"]
  end
end

# @return [String] host os, even on jruby
def host_os
  case RbConfig::CONFIG["host_os"]
  when /darwin/
    "darwin"
  when /linux/
    "linux"
  when /mingw|mswin/
    "mingw32"
  else
    RbConfig::CONFIG["host_os"]
  end
end

platform = PLATFORMS.keys.find { |p| Gem::Platform.new(p) === Gem::Platform.new(host_string) }
COMMON_BIN_PATH = File.expand_path("../bin/#{platform}/#{PLATFORMS[platform]}", File.dirname(__FILE__))

module Aws
  module Crt
    extend FFI::Library
    ffi_lib [COMMON_BIN_PATH, 'libaws-crt']
    attach_function :aws_crt_event_loop_group_new, [:int], :pointer
    attach_function :aws_crt_event_loop_group_destroy, [:pointer], :void

    attach_function :aws_crt_init, [], :void

    # TODO: test function for testing errors
    attach_function :aws_crt_test_error, [], :int
    attach_function :aws_crt_test_pointer_error, [], :pointer

    attach_function :aws_last_error, [], :int
    attach_function :aws_error_str, [:int], :string
    attach_function :aws_error_name, [:int], :string
    attach_function :aws_error_lib_name, [:int], :string
    attach_function :aws_error_debug_str, [:int], :string

    # Ensure aws_crt_init is called on library load
    aws_crt_init

    def self.call
      res = yield
      return unless res
      Errors.raise_last_error if res.is_a?(Integer) && res != 0
      Errors.raise_last_error if res == FFI::Pointer.new(0)
      res
    end

    # Base class for CRT Errors
    class Error < StandardError
    end

    module Errors

      @const_set_mutex = Mutex.new

      def self.raise_last_error
        error_code = Aws::Crt::aws_last_error
        error_name = Aws::Crt::aws_error_name(error_code)
        raise error_class(error_name), Aws::Crt::aws_error_debug_str(error_code)
      end

      # Get the error class for a given error_name
      def self.error_class(error_name)
        constant = error_class_constant(error_name)
        if error_const_set?(constant)
          # modeled error class exist
          # set code attribute
          err_class = const_get(constant)
          err_class
        else
          set_error_constant(constant)
        end
      end

      private

      # Convert an error code to an error class name/constant.
      # This requires filtering non-safe characters from the constant
      # name and ensuring it begins with an uppercase letter.
      def self.error_class_constant(error_name)
        constant = error_name.to_s.gsub(/AWS_ERROR_/, '').split('_').map{|e| e.capitalize}.join
      end

      def self.set_error_constant(constant)
        @const_set_mutex.synchronize do
          # Ensure the const was not defined while blocked by the mutex
          if error_const_set?(constant)
            const_get(constant)
          else
            error_class = Class.new(Aws::Crt::Error)
            const_set(constant, error_class)
          end
        end
      end

      def self.error_const_set?(constant)
        # Purposefully not using #const_defined? as that method returns true
        # for constants not defined directly in the current module.
        constants.include?(constant.to_sym)
      end
    end
  end
end

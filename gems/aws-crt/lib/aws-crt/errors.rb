# frozen_string_literal: true

module Aws
  module Crt
    # Base class for CRT Errors
    class Error < StandardError
    end

    # CRT Errors - includes utilities for mapping errors from CRT to
    # Ruby Exceptions
    module Errors
      @const_set_mutex = Mutex.new

      AWS_TO_RUBY_ERROR_MAP = {
        'AWS_ERROR_INVALID_INDEX' => IndexError,
        'AWS_ERROR_OOM' => NoMemoryError,
        'AWS_ERROR_UNIMPLEMENTED' => NotImplementedError,
        'AWS_ERROR_INVALID_ARGUMENT' => ArgumentError,
        'AWS_ERROR_SYS_CALL_FAILURE' => SystemCallError,
        'AWS_ERROR_DIVIDE_BY_ZERO' => ZeroDivisionError,
        'AWS_ERROR_HASHTBL_ITEM_NOT_FOUND' => KeyError
      }.freeze

      def self.raise_last_error
        error_code = Aws::Crt::Native.last_error
        return if error_code.zero?
        error_name = Aws::Crt::Native.error_name(error_code)
        msg = Aws::Crt::Native.error_debug_str(error_code)
        Aws::Crt::Native.reset_error
        raise error_class(error_name), msg
      end

      # Get the error class for a given error_name
      def self.error_class(error_name)
        if AWS_TO_RUBY_ERROR_MAP.include? error_name
          return AWS_TO_RUBY_ERROR_MAP[error_name]
        end

        constant = error_class_constant(error_name)
        if error_const_set?(constant)
          # modeled error class exist
          # set code attribute
          err_class = const_get(constant)
          err_class
        else
          add_error_constant(constant)
        end
      end

      # Convert an error code to an error class name/constant.
      # This requires filtering non-safe characters from the constant
      # name and ensuring it begins with an uppercase letter.
      def self.error_class_constant(error_name)
        error_name.to_s.gsub(/AWS_ERROR_/, '').split('_').map(&:capitalize).join
      end

      def self.add_error_constant(constant)
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

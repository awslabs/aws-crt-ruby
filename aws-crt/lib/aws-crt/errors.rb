module Aws::Crt
  # Base class for CRT Errors
  class Error < StandardError
  end

  module Errors
    @const_set_mutex = Mutex.new

    def self.raise_last_error
      error_code = Aws::Crt::Native.last_error
      error_name = Aws::Crt::Native.error_name(error_code)
      raise error_class(error_name), Aws::Crt::Native.error_debug_str(error_code)
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

    # Convert an error code to an error class name/constant.
    # This requires filtering non-safe characters from the constant
    # name and ensuring it begins with an uppercase letter.
    def self.error_class_constant(error_name)
      constant = error_name.to_s.gsub(/AWS_ERROR_/, '').split('_').map { |e| e.capitalize }.join
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

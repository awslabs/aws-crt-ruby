# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Signing Config
      class Signable
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:signing_config_release)

        # @param [Hash] options
        # @option options [required, Aws::Crt::Native::signing_algorithm]
        #   :algorithm
        def initialize(options = {}); end
      end
    end
  end
end

# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Signing Config
      class Signable
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:signable_release)

        # @param [Http::Message] http_request
        def initialize(http_request)
          manage_native do
            Aws::Crt::Native.signable_new_from_http_request(http_request.native)
          end
        end
      end
    end
  end
end

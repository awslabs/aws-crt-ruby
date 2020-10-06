# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      module Errors
        class MissingCredentialsError < ArgumentError
          def initialize(msg = nil)
            super(msg || <<-MSG.strip)
  missing credentials, provide credentials with one of the following options:
    - :access_key_id and :secret_access_key
    - :credentials
    - :credentials_provider
            MSG
          end
        end

        class MissingRegionError < ArgumentError
          def initialize(*_args)
            super('missing required option :region')
          end
        end
      end
    end
  end
end

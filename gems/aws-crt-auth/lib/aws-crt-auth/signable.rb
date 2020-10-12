# frozen_string_literal: true

module Aws
  module Crt
    module Auth
      # Signing Config
      class Signable
        include Aws::Crt::ManagedNative
        native_destroy Aws::Crt::Native.method(:signable_release)

        # @param [Hash] options
        # @option options [required, Hash[String,String]] :properties - Hash
        #   of String->String.  Should include properties for: uri, http_method
        # @option options [required, Hash[String,Hash[String,String]]]
        #   :property_lists - Should include headers.
        def initialize(options = {})
          manage_native do
            Aws::Crt::Native.signable_new
          end

          options.fetch(:properties, {}).each do |k, v|
            Aws::Crt::Native.signable_set_property(native, k, v)
          end

          options.fetch(:property_lists, {}).each do |k, h|
            # h.each do |p, v|
            #   Aws::Crt::Native.signable_append_property_list(native, k, p, v)
            # end
            keys, values, _pointers = Aws::Crt::Native.hash_to_native_arrays(h)
            Aws::Crt::Native.signable_set_property_list(
              native, k, h.size, keys, values
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'spec_helper'
require 'weakref'

module Aws
  module Crt
    module Auth #:nodoc:
      describe Signable do

        it 'works' do
          ptr = Aws::Crt::Native::signable_new()
          puts ptr
          puts Aws::Crt::Native::signable_set_property(ptr, 'name', 'value')
          puts Aws::Crt::Native::signable_get_property(ptr, 'name')
          Aws::Crt::Native::signable_release(ptr)
        end
      end
    end
  end
end
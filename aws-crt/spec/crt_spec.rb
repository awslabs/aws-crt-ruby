require 'spec_helper'

describe Aws::Crt do
  describe '#call' do
    it 'raises an error when called on a function that returns an int' do
      expect do
        Aws::Crt.call { Aws::Crt.aws_crt_test_error }
      end.to raise_error(Aws::Crt::Errors::InternalError)
    end

    it 'raises an error when called on a function that returns a pointer' do
      expect do
        Aws::Crt.call { Aws::Crt.aws_crt_test_pointer_error }
      end.to raise_error(Aws::Crt::Errors::InternalError)
    end
  end
end
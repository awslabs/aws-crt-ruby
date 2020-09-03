require 'spec_helper'

describe Aws::Crt do
  describe '#call' do
    it 'raises an error when called on a function that returns an int' do
      expect do
        Aws::Crt.call { Aws::Crt::Native.test_error(3) }
      end.to raise_error(Aws::Crt::Error)
    end

    it 'raises an error when called on a function that returns a pointer' do
      expect do
        Aws::Crt.call { Aws::Crt::Native.test_pointer_error }
      end.to raise_error(NoMemoryError)
    end
  end
end

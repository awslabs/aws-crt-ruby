# frozen_string_literal: true

require_relative 'spec_helper'

describe Aws::Crt::Native do
  describe '.attach_function' do
    it 'removes the aws_crt_ prefix from C functions' do
      expect(Aws::Crt::Native).to respond_to(:test_error)
      expect(Aws::Crt::Native).not_to respond_to(:aws_crt_test_error)
    end

    it 'creates a ! version of the function' do
      expect(Aws::Crt::Native).to respond_to(:test_error!)
    end

    it 'raises an error when called on a function that returns an int' do
      expect do
        Aws::Crt::Native.test_error(3)
      end.to raise_error(Aws::Crt::Error)
    end

    it 'raises an error when called on a function that returns a pointer' do
      expect do
        Aws::Crt::Native.test_pointer_error
      end.to raise_error(NoMemoryError)
    end

    it 'the ! function does not raise an error' do
      expect do
        Aws::Crt::Native.test_error!(3)
      end.not_to raise_error
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Aws::Crt::Errors do
  describe '.raise_last_error' do
    it 'translates and raises the last error' do
      Aws::Crt::Native.test_error(3) # generate an error
      expect do
        Aws::Crt::Errors.raise_last_error
      end.to raise_error(Aws::Crt::Error)
    end

    it 'does not raise when no error' do
      Aws::Crt::Native.test_error(0) # success
      expect do
        Aws::Crt::Errors.raise_last_error
      end.not_to raise_error
    end

    it 'resets the error after raising it' do
      Aws::Crt::Native.test_error(3) # raise error
      expect do
        Aws::Crt::Errors.raise_last_error
      end.to raise_error(Aws::Crt::Error)

      expect do
        Aws::Crt::Errors.raise_last_error
      end.not_to raise_error
    end
  end

  describe '.error_class' do
    let(:error_class) { Aws::Crt::Errors.error_class('AWS_ERROR_LIST_EMPTY') }
    it 'maps to ruby exceptions' do
      expect(Aws::Crt::Errors.error_class('AWS_ERROR_OOM')).to be NoMemoryError
    end

    it 'maps exceptions to subclasses of Aws::Crt::Error' do
      expect(error_class).to be < Aws::Crt::Error
    end
  end
end

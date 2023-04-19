# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::RaiseError do
  let(:configuration_error) do
    RgGen::Core::Configuration::ConfigurationError
  end

  let(:object) do
    klass = Class.new do
      include RgGen::Core::Configuration::RaiseError
    end
    klass.new
  end

  describe '#error_exception' do
    it 'ConfigurationErrorを返す' do
      expect(object.send(:error_exception)).to equal configuration_error
    end
  end
end

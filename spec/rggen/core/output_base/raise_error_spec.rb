# frozen_string_literal: true

RSpec.describe RgGen::Core::OutputBase::RaiseError do
  describe '#error' do
    let(:object) do
      Class.new { include RgGen::Core::OutputBase::RaiseError }.new
    end

    it '与えたメッセージと共にGeneratorErrorを起こす' do
      message = 'error !'
      expect { object.error(message) }
        .to raise_error RgGen::Core::GeneratorError, message
    end
  end
end

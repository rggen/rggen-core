# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::RaiseError do
  let(:message) { 'configuration error !' }

  let(:positions) { [Struct.new(:x, :y).new(0, 1), Struct.new(:x, :y).new(2, 3)]}

  let(:configuration_error) do
    RgGen::Core::Configuration::ConfigurationError
  end

  let(:object) do
    Class.new do
      include RgGen::Core::Configuration::RaiseError
      attr_writer :position
      def error_test(message, input_value = nil)
        if input_value
          error message, input_value
        else
          error message
        end
      end
    end.new
  end

  describe '#error_exception' do
    it 'ConfigurationErrorを返す' do
      expect(object.send(:error_exception)).to equal configuration_error
    end
  end

  describe '#error' do
    context '位置情報がない場合' do
      it '与えられたメッセージでConfigurationErrorを発生させる' do
        expect {
          object.error_test(message)
        }.to raise_rggen_error configuration_error, message
      end
    end

    context 'エラーの発生元が位置情報を持つ場合' do
      it '位置情報と与えられたメッセージでConfigurationErrorを発生させる' do
        object.position = positions[0]
        expect {
          object.error_test(message)
        }.to raise_rggen_error configuration_error, message, positions[0]
      end
    end

    context '与えられた入力値が位置情報を持つ場合' do
      let(:input_value) do
        RgGen::Core::InputBase::InputValue.new(0, positions[1])
      end

      it '入力値が持つ位置情報と与えられたメッセージでConfigurationErrorを発生させる' do
        expect {
          object.error_test(message, input_value)
        }.to raise_rggen_error configuration_error, message, positions[1]

        object.position = positions[0]
        expect {
          object.error_test(message, input_value)
        }.to raise_rggen_error configuration_error, message, positions[1]
      end
    end

    context '与えられた入力値が位置情報を持たない場合' do
      let(:input_value) do
        0
      end

      it '与えられたメッセージでConfigurationErrorを発生させる' do
        expect {
          object.error_test(message, input_value)
        }.to raise_rggen_error configuration_error, message

        object.position = positions[0]
        expect {
          object.error_test(message, input_value)
        }.to raise_rggen_error configuration_error, message, positions[0]
      end
    end
  end
end

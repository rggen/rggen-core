# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::InputData do
  describe '#value/#[]=' do
    let(:valid_value_lists) do
      { nil => [:foo, :bar] }
    end

    let(:position) do
      Struct.new(:x, :y).new(0, 1)
    end

    let(:input_data) do
      described_class.new(valid_value_lists)
    end

    def input_value(value)
      RgGen::Core::InputBase::InputValue.new(value, position)
    end

    def raise_configuration_error(message)
      raise_error RgGen::Core::Configuration::ConfigurationError, message
    end

    context '入力値名が入力値リスト上にない場合' do
      it 'ConfigurationErrorを起こす' do
        expect { input_data.value(:baz, input_value(0)) }
          .to raise_configuration_error 'unknown configuration field is given: baz'
        expect { input_data.value('baz', input_value(0)) }
          .to raise_configuration_error 'unknown configuration field is given: baz'

        expect { input_data[:baz] = input_value(0) }
          .to raise_configuration_error 'unknown configuration field is given: baz'

        expect { input_data['baz'] = input_value(0) }
          .to raise_configuration_error 'unknown configuration field is given: baz'

        expect { input_data.value(:foo, input_value(0)) }
          .not_to raise_error

        expect { input_data[:bar] = input_value(1) }
          .not_to raise_error
      end
    end
  end
end

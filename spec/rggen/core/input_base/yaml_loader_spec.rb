# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::YAMLLoader do
  describe '#load_yaml' do
    let(:loader) do
      klass = Class.new(RgGen::Core::InputBase::Loader) do
        include RgGen::Core::InputBase::YAMLLoader
        support_types [:yaml]

        def read_file(file)
          load_yaml(file)
        end

        def format_layer_data(read_data, _layer, _file)
          Hash(read_data)
        end
      end
      klass.new([], {})
    end

    let(:valid_value_lists) do
      { nil => [:foo, :bar, :baz, :fizz, :buzz] }
    end

    let(:file) do
      'test.yaml'
    end

    let(:input_data) do
      RgGen::Core::Configuration::InputData.new(valid_value_lists)
    end

    let(:file_content) do
      <<~'YAML'
        foo: 0
        bar: [1, 2]
        baz: {baz_3: 3, baz_4: 4}
        fizz:
          <<: &fizz_buzz
            fizz_buzz: [5, 6]
        buzz:
          <<: *fizz_buzz
      YAML
    end

    before do
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:binread).and_return(file_content)
    end

    def position(line, column)
      RgGen::Core::InputBase::YAMLLoader::Position.new(file, line, column)
    end

    specify '読みだした値は位置情報を持つ' do
      loader.load_file(file, input_data, valid_value_lists)
      expect(input_data[:foo]).to match_value(0, position(1, 6))
      expect(input_data[:bar].value[0]).to match_value(1, position(2, 7))
      expect(input_data[:bar].value[1]).to match_value(2, position(2, 10))
      expect(input_data[:baz].value[:baz_3]).to match_value(3, position(3, 14))
      expect(input_data[:baz].value[:baz_4]).to match_value(4, position(3, 24))
      expect(input_data[:fizz].value[:fizz_buzz][0]).to match_value(5, position(6, 17))
      expect(input_data[:fizz].value[:fizz_buzz][1]).to match_value(6, position(6, 20))
      expect(input_data[:buzz].value[:fizz_buzz][0]).to match_value(5, position(6, 17))
      expect(input_data[:buzz].value[:fizz_buzz][1]).to match_value(6, position(6, 20))
    end
  end
end

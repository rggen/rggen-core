# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::YAMLLoader do
  describe '#load_yaml' do
    let(:loader) do
      klass = Class.new(RgGen::Core::InputBase::Loader) do
        include RgGen::Core::InputBase::YAMLLoader
        support_types [:yaml]

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
          <<: &fizz_buzz_0
            fizz_buzz_0: [5, 6]
        buzz:
          <<: *fizz_buzz_0
          fizz_buzz_1: [7, 8]
      YAML
    end

    before do
      mock_file_io(file, file_content)
    end

    def position(line, column)
      YPS::Position.new(file, line, column)
    end

    specify '読みだした値は位置情報を持つ' do
      loader.load_data(input_data, valid_value_lists, file)
      expect(input_data[:foo]).to match_value(0, position(1, 6))
      expect(input_data[:bar]).to match_value(
        match([match_value(1, position(2, 7)), match_value(2, position(2, 10))]),
        position(2, 6)
      )
      expect(input_data[:baz]).to match_value(
        match(baz_3: match_value(3, position(3, 14)), baz_4: match_value(4, position(3, 24))),
        position(3, 6)
      )
      expect(input_data[:fizz]).to match_value(
        match(
          fizz_buzz_0: match_value(
            match([match_value(5, position(6, 19)), match_value(6, position(6, 22))]),
            position(6, 18)
          )
        ),
        position(5, 3)
      )
      expect(input_data[:buzz]).to match_value(
        match(
          fizz_buzz_0: match_value(
            match([match_value(5, position(6, 19)), match_value(6, position(6, 22))]),
            position(6, 18)
          ),
          fizz_buzz_1: match_value(
            match([match_value(7, position(9, 17)), match_value(8, position(9, 20))]),
            position(9, 16)
          )
        ),
        position(8, 3)
      )
    end
  end
end

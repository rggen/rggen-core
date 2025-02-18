# frozen_string_literal: true

RSpec.describe RgGen::Core::RegisterMap::TOMLLoader do
  let(:loader) { described_class.new([], {}) }

  let(:file) { 'foo.toml' }

  describe '#support?' do
    let(:supported_file) { file }

    let(:unsupported_files) do
      random_file_extensions(max_length: 5, exceptions: ['json'])
        .map { |extension| "foo.#{extension}" }
    end

    it 'toml形式のフィルに対応する' do
      expect(loader.support?(supported_file)).to be true
      unsupported_files.each do |file|
        expect(loader.support?(file)).to be false
      end
    end
  end

  describe '#load_file' do
    let(:valid_value_lists) do
      {
        root: [], register_block: [:foo], register_file: [:bar],
        register: [:baz], bit_field: [:qux]
      }
    end

    let(:input_data) do
      RgGen::Core::RegisterMap::InputData.new(:root, valid_value_lists, nil)
    end

    let(:file_content) do
      <<~'TOML'
        [[register_blocks]]
        foo = "foo_0"
        [[register_blocks.registers]]
        baz = "baz_0_0"
        bit_fields = [
          { qux = "qux_0_0_0" },
          { qux = "qux_0_0_1" }
        ]
        [[register_blocks.registers]]
        baz = "baz_0_1"
        bit_fields = [
          { qux = "qux_0_1_0" }
        ]
        [[register_blocks]]
        foo = "foo_1"
        [[register_blocks.register_files]]
        bar = "bar_1_0"
        [[register_blocks.register_files.registers]]
        baz = "baz_1_0_0"
        bit_fields = [
          { qux = "qux_1_0_0_0" }
        ]
        [[register_blocks.register_files]]
        bar = "bar_1_1"
        [[register_blocks.register_files.registers]]
        baz = "baz_1_1_0"
        bit_fields = [
          { qux = "qux_1_1_0_0" }
        ]
        [[register_blocks.registers]]
        baz = "baz_1_2"
        bit_fields = [
          { qux = "qux_1_2_0" }
        ]
      TOML
    end

    let(:register_blocks) { input_data.children }

    let(:register_files) do
      collect_target_data(input_data, :register_file)
    end

    let(:registers) do
      collect_target_data(input_data, :register)
    end

    let(:bit_fields) { registers.flat_map(&:children) }

    def collect_target_data(input_data, layer)
      [
        *input_data.children.select { |data| data.layer == layer },
        *input_data.children.flat_map { |data| collect_target_data(data, layer) }
      ]
    end

    before do
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:binread).and_return(file_content)
    end

    it '入力したTOMLファイルを元に、入力データを組み立てる' do
      loader.load_data(input_data, valid_value_lists, file)
      expect(register_blocks).to match [
        have_value(:foo, 'foo_0'), have_value(:foo, 'foo_1')
      ]
      expect(register_files).to match [
        have_value(:bar, 'bar_1_0'), have_value(:bar, 'bar_1_1')
      ]
      expect(registers).to match [
        have_value(:baz, 'baz_0_0'), have_value(:baz, 'baz_0_1'), have_value(:baz, 'baz_1_2'),
        have_value(:baz, 'baz_1_0_0'), have_value(:baz, 'baz_1_1_0'),
      ]
      expect(bit_fields).to match [
        have_value(:qux, 'qux_0_0_0'), have_value(:qux, 'qux_0_0_1'), have_value(:qux, 'qux_0_1_0'),
        have_value(:qux, 'qux_1_2_0'), have_value(:qux, 'qux_1_0_0_0'), have_value(:qux, 'qux_1_1_0_0')
      ]
    end
  end
end

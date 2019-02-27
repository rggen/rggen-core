# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::RegisterMap
  describe YAMLLoader do
    let(:loader) { YAMLLoader }

    let(:files) { ['foo.yaml', 'foo.yml'] }

    describe ".support?" do
      let(:supported_files) { files }

      let(:unsupported_files) do
        random_file_extensions(max_length: 5, exceptions: ['yaml', 'yml'])
          .map { |extension| "foo.#{extension}" }
      end

      let(:unsupported_file) { 'foo.txt' }

      it "yaml/yml形式のフィルに対応する" do
        supported_files.each do |file|
          expect(loader.support?(file)).to be true
        end

        unsupported_files.each do |file|
          expect(loader.support?(file)).to be false
        end
      end
    end

    describe ".load_file" do
      let(:valid_value_lists) do
        [[], [:foo], [:bar], [:baz]]
      end

      let(:input_data) do
        InputData.new(:register_map, valid_value_lists)
      end

      let(:file) { files.sample }

      let(:file_contents) do
        <<'YAML'
register_blocks:
- foo: foo_0
  registers:
  - bar: bar_0_0
    bit_fields:
    - baz: baz_0_0_0
    - baz: baz_0_0_1
  - bar: bar_0_1
    bit_fields:
      - baz: baz_0_1_0
- foo: foo_1
  registers:
    - bar: bar_1_0
      bit_fields:
      - baz: baz_1_0_0
    - bar: bar_1_1
      bit_fields:
      - baz: baz_1_1_0
      - baz: baz_1_1_1
YAML
      end

      let(:register_blocks) { input_data.children }

      let(:registers) { register_blocks.flat_map(&:children) }

      let(:bit_fields) { registers.flat_map(&:children) }

      before do
        allow(File).to receive(:readable?).and_return(true)
        allow(File).to receive(:binread).and_return(file_contents)
      end

      it "入力したYAMLファイルを元に、入力データを組み立てる" do
        loader.load_file(file, input_data, valid_value_lists)
        expect(register_blocks).to match [
          have_value(:foo, 'foo_0'), have_value(:foo, 'foo_1')
        ]
        expect(registers).to match [
          have_value(:bar, 'bar_0_0'), have_value(:bar, 'bar_0_1'),
          have_value(:bar, 'bar_1_0'), have_value(:bar, 'bar_1_1')
        ]
        expect(bit_fields).to match [
          have_value(:baz, 'baz_0_0_0'), have_value(:baz, 'baz_0_0_1'), have_value(:baz, 'baz_0_1_0'),
          have_value(:baz, 'baz_1_0_0'), have_value(:baz, 'baz_1_1_0'), have_value(:baz, 'baz_1_1_1')
        ]
      end
    end
  end
end

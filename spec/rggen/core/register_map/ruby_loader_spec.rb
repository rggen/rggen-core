# frozen_string_literal: true

RSpec.describe RgGen::Core::RegisterMap::RubyLoader do
  let(:loader) { described_class.new([], {}) }

  let(:file) { 'ruby.rb' }

  describe '#support?' do
    let(:supported_file) { file }

    let(:unsupported_files) do
      random_file_extensions(max_length: 3, exceptions: ['rb'])
        .map { |extension| "foo.#{extension}" }
    end

    it 'rb形式のファイルに対応する' do
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
      <<~'RUBY'
        register_block {
          foo 'foo_0'
          register {
            baz 'baz_0_0'
            bit_field { qux 'qux_0_0_0' }
            bit_field { qux 'qux_0_0_1' }
          }
          register {
            baz 'baz_0_1'
            bit_field { qux 'qux_0_1_0' }
          }
        }
        register_block {
          foo 'foo_1'
          register_file {
            bar 'bar_1_0'
            register {
              baz 'baz_1_0_0'
              bit_field { qux 'qux_1_0_0_0' }
            }
          }
          register_file {
            bar 'bar_1_1'
            register {
              baz 'baz_1_1_0'
              bit_field { qux 'qux_1_1_0_0' }
            }
          }
          register {
            baz 'baz_1_2'
            bit_field { qux 'qux_1_2_0' }
          }
        }
      RUBY
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

    it '入力したフィアルを元に、入力データを組み立てる' do
      loader.load_file(file, input_data, valid_value_lists)
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

    it '位置情報に入力ファイルでの位置を設定する' do
      loader.load_file(file, input_data, valid_value_lists)
      expect(register_blocks[0][:foo].position).to have_attributes(path: file, lineno: 2)
      expect(registers[0][:baz].position).to have_attributes(path: file, lineno: 4)
      expect(bit_fields[0][:qux].position).to have_attributes(path: file, lineno: 5)
      expect(bit_fields[1][:qux].position).to have_attributes(path: file, lineno: 6)
      expect(registers[1][:baz].position).to have_attributes(path: file, lineno: 9)
      expect(bit_fields[2][:qux].position).to have_attributes(path: file, lineno: 10)

      expect(register_blocks[1][:foo].position).to have_attributes(path: file, lineno: 14)
      expect(register_files[0][:bar].position).to have_attributes(path: file, lineno: 16)
      expect(registers[3][:baz].position).to have_attributes(path: file, lineno: 18)
      expect(bit_fields[4][:qux].position).to have_attributes(path: file, lineno: 19)
      expect(register_files[1][:bar].position).to have_attributes(path: file, lineno: 23)
      expect(registers[4][:baz].position).to have_attributes(path: file, lineno: 25)
      expect(bit_fields[5][:qux].position).to have_attributes(path: file, lineno: 26)
      expect(registers[2][:baz].position).to have_attributes(path: file, lineno: 30)
      expect(bit_fields[3][:qux].position).to have_attributes(path: file, lineno: 31)
    end
  end
end

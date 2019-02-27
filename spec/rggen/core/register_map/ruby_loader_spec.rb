# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::RegisterMap
  describe RubyLoader do
    let(:loader) { RubyLoader }

    let(:file) { 'ruby.rb' }

    describe ".support?" do
      let(:supported_file) { file }

      let(:unsupported_files) do
        random_file_extensions(max_length: 3, exceptions: ['rb'])
          .map { |extension| "foo.#{extension}" }
      end

      it "rb形式のファイルに対応する" do
        expect(loader.support?(supported_file)).to be true
        unsupported_files.each do |file|
          expect(loader.support?(file)).to be false
        end
      end
    end

    describe ".load_file" do
      let(:valid_value_lists) do
        [[], [:foo], [:bar], [:baz]]
      end

      let(:input_data) { InputData.new(:register_map, valid_value_lists) }

      let(:file_contents) do
        <<'RUBY'
register_block {
  foo 'foo_0'
  register {
    bar 'bar_0_0'
    bit_field { baz 'baz_0_0_0' }
    bit_field { baz 'baz_0_0_1' }
  }
  register {
    bar 'bar_0_1'
    bit_field { baz 'baz_0_1_0' }
  }
}

register_block {
  foo 'foo_1'
  register {
    bar 'bar_1_0'
    bit_field { baz 'baz_1_0_0' }
  }
  register {
    bar 'bar_1_1'
    bit_field { baz 'baz_1_1_0' }
    bit_field { baz 'baz_1_1_1' }
  }
}
RUBY
      end

      let(:register_blocks) { input_data.children }

      let(:registers) { register_blocks.flat_map(&:children) }

      let(:bit_fields) { registers.flat_map(&:children) }

      before do
        allow(File).to receive(:readable?).and_return(true)
        allow(File).to receive(:binread).and_return(file_contents)
      end

      it "入力したフィアルを元に、入力データを組み立てる" do
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

      it "位置情報に入力ファイルでの位置を設定する" do
        loader.load_file(file, input_data, valid_value_lists)
        expect(register_blocks[0][:foo].position).to have_attributes(path: file, lineno: 2)
        expect(registers[0][:bar].position).to have_attributes(path: file, lineno: 4)
        expect(bit_fields[0][:baz].position).to have_attributes(path: file, lineno: 5)
        expect(bit_fields[1][:baz].position).to have_attributes(path: file, lineno: 6)
        expect(registers[1][:bar].position).to have_attributes(path: file, lineno: 9)
        expect(bit_fields[2][:baz].position).to have_attributes(path: file, lineno: 10)

        expect(register_blocks[1][:foo].position).to have_attributes(path: file, lineno: 15)
        expect(registers[2][:bar].position).to have_attributes(path: file, lineno: 17)
        expect(bit_fields[3][:baz].position).to have_attributes(path: file, lineno: 18)
        expect(registers[3][:bar].position).to have_attributes(path: file, lineno: 21)
        expect(bit_fields[4][:baz].position).to have_attributes(path: file, lineno: 22)
        expect(bit_fields[5][:baz].position).to have_attributes(path: file, lineno: 23)
      end
    end
  end
end

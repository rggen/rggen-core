# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Configuration
  describe JSONLoader do
    let(:loader) { JSONLoader }

    let(:file) { 'foo.json' }

    describe ".support?" do
      let(:supported_file) { file }

      let(:unsupported_files) do
        random_file_extensions(max_length: 5, exceptions: ['json'])
          .map { |extension| "foo.#{extension}" }
      end

      it "json形式のファイルに対応する" do
        expect(loader.support?(supported_file)).to be true
        unsupported_files.each do |file|
          expect(loader.support?(file)).to be false
        end
      end
    end

    describe ".load_file" do
      let(:valid_value_lists) { [[:foo, :bar, :baz]] }

      let(:input_data) { RgGen::Core::InputBase::InputData.new(valid_value_lists) }

      let(:file_contents) do
        <<'JSON'
{
  "foo": 0,
  "bar": 1,
  "baz": 2
}
JSON
      end

      before do
        allow(File).to receive(:readable?).and_return(true)
        allow(File).to receive(:binread).and_return(file_contents)
      end

      it "入力ファイルを元に、入力データを組み立てる" do
        loader.load_file(file, input_data, valid_value_lists)
        expect(input_data).to have_values([:foo, 0, file], [:bar, 1, file], [:baz, 2, file])
      end
    end
  end
end

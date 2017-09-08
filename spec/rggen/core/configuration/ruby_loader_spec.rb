require 'spec_helper'

module RgGen::Core::Configuration
  describe RubyLoader do
    let(:loader) { RubyLoader }

    let(:file) { 'ruby.rb' }

    describe ".support?" do
      it "rb形式のファイルに対応する" do
        expect(loader.support?(file)).to be true
      end
    end

    describe ".load_file" do
      let(:valid_value_lists) { [[:foo, :bar, :baz]] }

      let(:input_data) { RgGen::Core::InputBase::InputData.new(valid_value_lists) }

      let(:file_contents) do
        <<'RUBY'
foo 0
bar 1
baz 2
RUBY
      end

      before do
        allow(File).to receive(:readable?).and_return(true)
        allow(File).to receive(:binread).and_return(file_contents)
      end

      before do
        loader.load_file(file, input_data, valid_value_lists)
      end

      it "入力したファイルを元に、入力データを組み立てる" do
        expect(input_data).to have_values([:foo, 0], [:bar, 1], [:baz, 2])
      end

      it "位置情報に入力ファイルでの位置を設定する" do
        expect(input_data[:foo].position).to have_attributes(path: file, lineno: 1)
        expect(input_data[:bar].position).to have_attributes(path: file, lineno: 2)
        expect(input_data[:baz].position).to have_attributes(path: file, lineno: 3)
      end
    end
  end
end

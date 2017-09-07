require 'spec_helper'

module RgGen::Core::InputBase
  describe Loader do
    def define_loader(&body)
      Class.new(Loader, &body)
    end

    describe ".support?" do
      let(:loader) do
        define_loader { supported_types [:csv, :txt] }
      end

      let(:supported_files) do
        %w(test.csv test.txt test.CSV test.TxT)
      end

      let(:unsupported_files) do
        %w(test.xls test.csvv test.ttxt)
      end

      it "入力ファイルが、.supported_typesで登録された、対応する拡張子を持つかどうかを返す" do
        aggregate_failures do
          supported_files.each do |file|
            expect(loader.support?(file)).to be true
          end
        end

        aggregate_failures do
          unsupported_files.each do |file|
            expect(loader.support?(file)).to be false
          end
        end
      end
    end

    describe ".load_file" do
      let(:loader) do
        define_loader do
          def read_file(file)
            binding.eval(File.read(file))
          end
          def form(read_data, _file)
            input_data.values foo_data(read_data)
            input_data.bar bar_data(read_data)
          end
          def foo_data(read_data)
            Hash[valid_value_lists[0].zip(read_data[0])]
          end
          def bar_data(read_data)
            Hash[valid_value_lists[1].zip(read_data[1])]
          end
        end
      end

      let(:input_data) do
        Class.new(InputData) do
          def initialize(valid_value_lists)
            super(valid_value_lists)
          end

          def bar(value_list = nil, &block)
            child(value_list, &block)
          end
        end.new(valid_value_lists)
      end

      let(:valid_value_lists) { [[:foo_0, :foo_1], [:bar_0, :bar_1]] }

      let(:file_contents) do
        <<'FILE'
[
  [0, 1], [2, 3]
]
FILE
      end

      let(:file_name) { 'foo_bar.rb' }

      before do
        allow(File).to receive(:readable?).with(file_name).and_return(true)
        allow(File).to receive(:read).with(file_name).and_return(file_contents)
      end

      it "指定されたファイルを読み出す" do
        loader.load_file(file_name, input_data, valid_value_lists)
        expect(File).to have_received(:read).with(file_name)
      end

      context "ファイル読み出しに成功した場合" do
        before { loader.load_file(file_name, input_data, valid_value_lists) }

        let(:foo_values) do
          {}.tap do |values|
            input_data.values.each { |name, value| values[name] = value.value }
          end
        end

        let(:bar_values) do
          {}.tap do |values|
            input_data.children[0].values.each { |name, value| values[name] = value.value }
          end
        end

        it "指定されたファイルを読み込んで、与えられた入力データを組み立てる" do
          expect(foo_values).to match foo_0: 0, foo_1: 1
          expect(bar_values).to match bar_0: 2, bar_1: 3
        end
      end

      context "ファイルが存在しない場合" do
        let(:invalid_file_name) { 'baz.rb' }

        before do
          allow(File).to receive(:readable?).with(invalid_file_name).and_return(false)
        end

        it "LoadErrorを起こす" do
          expect {
            loader.load_file(invalid_file_name, input_data, valid_value_lists)
          }.to raise_error RgGen::Core::LoadError, "cannot load such file -- #{invalid_file_name}"
        end
      end
    end
  end
end

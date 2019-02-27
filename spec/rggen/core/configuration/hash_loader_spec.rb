# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Configuration
  describe HashLoader do
    let(:valid_value_lists) { [[:foo, :bar, :baz]] }

    let(:input_data) { RgGen::Core::InputBase::InputData.new(valid_value_lists) }

    let(:loader) do
      Class.new(Loader) do
        class << self
          attr_accessor :load_data
        end

        include HashLoader

        def read_file(file)
          self.class.load_data
        end
      end
    end

    let(:file) { 'foo.txt' }

    before do
      allow(File).to receive(:readable?).and_return(true)
    end

    context "#read_dataがHashを返す場合" do
      let(:load_data) { { foo: 0, bar: 1, qux: 2} }

      before do
        loader.load_data = load_data
        loader.load_file(file, input_data, valid_value_lists)
      end

      it "読み出したHashを使って、入力データを組み立てる" do
        expect(input_data).to have_value(:foo, 0, file)
        expect(input_data).to have_value(:bar, 1, file)
        expect(input_data[:baz]).to be_empty_value
      end
    end

    context "#read_dataがnilを返す場合" do
      before do
        loader.load_data = nil
        loader.load_file(file, input_data, valid_value_lists)
      end

      it "空のHashとして、入力データを組み立てる" do
        expect(input_data[:foo]).to be_empty_value
        expect(input_data[:bar]).to be_empty_value
        expect(input_data[:baz]).to be_empty_value
      end
    end

    context "#read_dataが空の配列を返す場合" do
      before do
        loader.load_data = []
        loader.load_file(file, input_data, valid_value_lists)
      end

      it "空のHashとして、入力データを組み立てる" do
        expect(input_data[:foo]).to be_empty_value
        expect(input_data[:bar]).to be_empty_value
        expect(input_data[:baz]).to be_empty_value
      end
    end

    context "#read_dataがHash以外を返す場合" do
      let(:invalid_load_data) do
        [0, Object.new, [:foo, 0, :bar, 1], "foo: 0, bar: 1"]
      end

      it "LoadErrorを起こす" do
        invalid_load_data.each do |load_data|
          expect {
            loader.load_data = load_data
            loader.load_file(file, input_data, valid_value_lists)
          }.to raise_error RgGen::Core::LoadError, "can't convert #{load_data.class} into Hash -- #{file}"
        end
      end
    end
  end
end

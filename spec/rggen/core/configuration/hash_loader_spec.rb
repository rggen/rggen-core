# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::HashLoader do
  let(:valid_value_lists) do
    { nil => [:foo, :bar, :baz] }
  end

  let(:input_data) { RgGen::Core::Configuration::InputData.new(valid_value_lists) }

  let(:loader) do
    loader_class = Class.new(RgGen::Core::Configuration::Loader) do
      include RgGen::Core::Configuration::HashLoader
      attr_accessor :load_data
      def read_file(_file)
        load_data
      end
    end
    loader_class.new([], {})
  end

  let(:file) { 'foo.txt' }

  before do
    allow(File).to receive(:readable?).and_return(true)
  end

  context '#read_dataがHashを返す場合' do
    let(:load_data) { { foo: 0, bar: 1 } }

    before do
      loader.load_data = load_data
      loader.load_file(file, input_data, valid_value_lists)
    end

    it '読み出したHashを使って、入力データを組み立てる' do
      expect(input_data).to have_value(:foo, 0, file)
      expect(input_data).to have_value(:bar, 1, file)
      expect(input_data[:baz]).to be_empty_value
    end
  end

  context '#read_dataがnilを返す場合' do
    before do
      loader.load_data = nil
      loader.load_file(file, input_data, valid_value_lists)
    end

    it '空のHashとして、入力データを組み立てる' do
      expect(input_data[:foo]).to be_empty_value
      expect(input_data[:bar]).to be_empty_value
      expect(input_data[:baz]).to be_empty_value
    end
  end

  context '#read_dataが空の配列を返す場合' do
    before do
      loader.load_data = []
      loader.load_file(file, input_data, valid_value_lists)
    end

    it '空のHashとして、入力データを組み立てる' do
      expect(input_data[:foo]).to be_empty_value
      expect(input_data[:bar]).to be_empty_value
      expect(input_data[:baz]).to be_empty_value
    end
  end

  context '#read_dataがHash以外を返す場合' do
    let(:invalid_load_data) do
      [0, Object.new, [:foo, 0, :bar, 1], 'foo: 0, bar: 1']
    end

    it 'LoadErrorを起こす' do
      invalid_load_data.each do |load_data|
        expect {
          loader.load_data = load_data
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{load_data.class} into Hash", file
      end
    end
  end
end

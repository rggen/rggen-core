# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::TOMLLoader do
  let(:loader) { described_class.new([], {}) }

  let(:file) { 'foo.toml' }

  describe '#support?' do
    let(:supported_file) { file }

    let(:unsupported_files) do
      random_file_extensions(max_length: 5, exceptions: ['toml'])
        .map { |extension| "foo.#{extension}" }
    end

    it 'toml形式のファイルに対応する' do
      expect(loader.support?(supported_file)).to be true
      unsupported_files.each do |file|
        expect(loader.support?(file)).to be false
      end
    end
  end

  describe '#load_file' do
    let(:valid_value_lists) do
      { nil => [:foo, :bar, :baz] }
    end

    let(:input_data) { RgGen::Core::Configuration::InputData.new(valid_value_lists) }

    let(:file_content) do
      <<~'TOML'
        foo = 0
        bar = 1
        baz = 2
      TOML
    end

    before do
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:binread).and_return(file_content)
    end

    it '入力ファイルを元に、入力データを組み立てる' do
      loader.load_data(input_data, valid_value_lists, file)
      expect(input_data).to have_values([:foo, 0, file], [:bar, 1, file], [:baz, 2, file])
    end
  end
end

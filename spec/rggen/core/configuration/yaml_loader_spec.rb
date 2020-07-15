# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::YAMLLoader do
  let(:loader) do
    RgGen::Core::Configuration::YAMLLoader.new
  end

  let(:files) { ['foo.yaml', 'foo.yml'] }

  describe '#support?' do
    let(:supported_files) { files }

    let(:unsupported_files) do
      random_file_extensions(max_length: 5, exceptions: ['yaml', 'yml'])
        .map { |extension| "foo.#{extension}" }
    end

    it 'yaml/yml形式のファイルに対応する' do
      supported_files.each do |file|
        expect(loader.support?(file)).to be true
      end

      unsupported_files.each do |file|
        expect(loader.support?(file)).to be false
      end
    end
  end

  describe '#load_file' do
    let(:valid_value_lists) do
      { nil => [:foo, :bar, :baz, :fizz, :buzz] }
    end

    let(:input_data) { RgGen::Core::Configuration::InputData.new(valid_value_lists) }

    let(:file) { files.sample }

    let(:file_content) do
      <<~'YAML'
        foo: 0
        bar: 1
        baz: 2
        fizz: fizz
        buzz: :buzz
      YAML
    end

    before do
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:binread).and_return(file_content)
    end

    it '入力ファイルを元に、入力データを組み立てる' do
      loader.load_file(file, input_data, valid_value_lists)
      expect(input_data).to have_values(
        [:foo, 0, file], [:bar, 1, file], [:baz, 2, file],
        [:fizz, 'fizz', file], [:buzz, :buzz, file]
      )
    end
  end
end

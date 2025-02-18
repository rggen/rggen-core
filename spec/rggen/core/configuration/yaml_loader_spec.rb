# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::YAMLLoader do
  let(:loader) { described_class.new([], {}) }

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

    def position(line, column)
      RgGen::Core::InputBase::YAMLLoader::Position.new(file, line, column)
    end

    it '入力ファイルを元に、入力データを組み立てる' do
      loader.load_data(input_data, valid_value_lists, file)
      expect(input_data).to have_values(
        [:foo, 0, position(1, 6)],
        [:bar, 1, position(2, 6)],
        [:baz, 2, position(3, 6)],
        [:fizz, 'fizz', position(4, 7)],
        [:buzz, :buzz, position(5, 7)]
      )
    end
  end
end

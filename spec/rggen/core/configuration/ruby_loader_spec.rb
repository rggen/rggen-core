# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::RubyLoader do
  let(:loader) do
    RgGen::Core::Configuration::RubyLoader
  end

  let(:file) { 'ruby.rb' }

  describe '.support?' do
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

  describe '.load_file' do
    let(:valid_value_lists) do
      { nil => [:foo, :bar, :baz] }
    end

    let(:input_data) { RgGen::Core::Configuration::InputData.new(valid_value_lists) }

    let(:file_content) do
      <<~'RUBY'
        foo 0
        bar 1
        baz 2
      RUBY
    end

    before do
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:binread).and_return(file_content)
    end

    it '入力したファイルを元に、入力データを組み立てる' do
      loader.load_file(file, input_data, valid_value_lists)
      expect(input_data).to have_values([:foo, 0], [:bar, 1], [:baz, 2])
    end

    it '位置情報に入力ファイルでの位置を設定する' do
      loader.load_file(file, input_data, valid_value_lists)
      expect(input_data[:foo].position).to have_attributes(path: file, lineno: 1)
      expect(input_data[:bar].position).to have_attributes(path: file, lineno: 2)
      expect(input_data[:baz].position).to have_attributes(path: file, lineno: 3)
    end
  end
end

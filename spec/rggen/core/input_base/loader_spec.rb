# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::Loader do
  def define_loader(&body)
    Class.new(described_class, &body)
  end

  describe '.support?' do
    let(:loader) do
      define_loader { support_types [:csv, :txt] }
    end

    let(:support_extensions) do
      ['csv', 'txt']
    end

    let(:support_files) do
      support_extensions.map { |extention| "test.#{random_updown_case(extention)}" }
    end

    let(:unsupport_extensions) do
      random_file_extensions(max_length: 4, exceptions: support_extensions)
    end

    let(:unsupport_files) do
      unsupport_extensions.map { |extention| "test.#{extention}" }
    end

    it '入力ファイルが、.support_typesで登録された、対応する拡張子を持つかどうかを返す' do
      aggregate_failures do
        support_files.each do |file|
          expect(loader.support?(file)).to be true
        end
      end

      aggregate_failures do
        unsupport_files.each do |file|
          expect(loader.support?(file)).to be false
        end
      end
    end
  end

  describe '.load_file' do
    let(:loader) do
      define_loader do
        def read_file(file)
          binding.eval(File.read(file))
        end
        def format(read_data, _file)
          input_data.values foo_data(read_data)
          input_data.bar bar_data(read_data)
        end
        def foo_data(read_data)
          Hash[valid_value_lists[:foo].zip(read_data[0])]
        end
        def bar_data(read_data)
          Hash[valid_value_lists[:bar].zip(read_data[1])]
        end
      end
    end

    let(:input_data) do
      Class.new(RgGen::Core::InputBase::InputData) do
        def bar(value_list = nil, &block)
          child(:bar, value_list, &block)
        end
      end.new(:foo, valid_value_lists)
    end

    let(:valid_value_lists) do
      { foo: [:foo_0, :foo_1], bar: [:bar_0, :bar_1] }
    end

    let(:file_content) do
      <<~'FILE'
        [
          [0, 1], [2, 3]
        ]
      FILE
    end

    let(:file_name) { 'foo_bar.rb' }

    before do
      allow(File).to receive(:readable?).with(file_name).and_return(true)
      allow(File).to receive(:read).with(file_name).and_return(file_content)
    end

    it '指定されたファイルを読み出す' do
      loader.load_file(file_name, input_data, valid_value_lists)
      expect(File).to have_received(:read).with(file_name)
    end

    context 'ファイル読み出しに成功した場合' do
      before { loader.load_file(file_name, input_data, valid_value_lists) }

      it '指定されたファイルを読み込んで、与えられた入力データを組み立てる' do
        expect(input_data).to have_values([:foo_0, 0], [:foo_1, 1])
        expect(input_data.children[0]).to have_values([:bar_0, 2], [:bar_1, 3])
      end
    end

    context 'ファイルが存在しない場合' do
      let(:invalid_file_name) { 'baz.rb' }

      before do
        allow(File).to receive(:readable?).with(invalid_file_name).and_return(false)
      end

      it 'LoadErrorを起こす' do
        expect {
          loader.load_file(invalid_file_name, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, 'cannot load such file', invalid_file_name
      end
    end
  end
end

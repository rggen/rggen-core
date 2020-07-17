# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::Loader do
  def define_loader(loader_base = nil, &body)
    Class.new(loader_base || described_class, &body)
  end

  def create_extractor(layer, value, &body)
    Class.new(RgGen::Core::InputBase::InputDataExtractor) { extract(&body) }.new(layer, value)
  end

  describe '#support?' do
    let(:loader) do
      define_loader { support_types [:csv, :txt] }.new([], {})
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

  describe '#load_file' do
    let(:valid_value_lists) do
      {
        foo: [:fizz_0, :buzz_0],
        bar: [:fizz_1, :buzz_1],
        baz: [:fizz_2, :buzz_2]
      }
    end

    let(:input_data) do
      RgGen::Core::InputBase::InputData.new(:foo, valid_value_lists)
    end

    let(:foo_data) do
      input_data
    end

    let(:bar_data) do
      input_data.children
    end

    let(:baz_data) do
      bar_data.flat_map(&:children)
    end

    let(:file_content) do
      <<~'FILE'
        [
          [:a, :b],
          [[:c, :d], [[:e, :f]], [[:g, :h]]],
          [[:i, :j], [[:k, :l]], [[:m, :n]]]
        ]
      FILE
    end

    let(:file_name) { 'foo_bar_baz.rb' }

    let(:loader_base) do
      define_loader do
        def read_file(file)
          eval(File.read(file))
        end
        def format_sub_layer_data(read_data, layer, _file)
          if layer == :foo
            { bar: read_data[1..-1] }
          elsif layer == :bar
            { baz: read_data[1..-1] }
          end
        end
      end
    end

    let(:simple_loader) do
      define_loader(loader_base) do
        def format_layer_data(read_data, layer, _file)
          @valid_value_lists[layer].zip(read_data[0]).to_h
        end
      end
    end

    before do
      allow(File).to receive(:readable?).with(file_name).and_return(true)
      allow(File).to receive(:read).with(file_name).and_return(file_content)
    end

    context '#format_layer_dataが定義されている場合' do
      specify '#format_layer_dataの戻り値が、その階層の入力データとなる' do
        loader = simple_loader.new([], {})
        loader.load_file(file_name, input_data, valid_value_lists)
        expect(foo_data).to have_values([:fizz_0, :a], [:buzz_0, :b])
        expect(bar_data[0]).to have_values([:fizz_1, :c], [:buzz_1, :d])
        expect(baz_data[0]).to have_values([:fizz_2, :e], [:buzz_2, :f])
        expect(baz_data[1]).to have_values([:fizz_2, :g], [:buzz_2, :h])
        expect(bar_data[1]).to have_values([:fizz_1, :i], [:buzz_1, :j])
        expect(baz_data[2]).to have_values([:fizz_2, :k], [:buzz_2, :l])
        expect(baz_data[3]).to have_values([:fizz_2, :m], [:buzz_2, :n])
      end
    end

    context '#format_layer_dataが定義されておらず、input_data_extractorsが指定されている場合' do
      specify 'input_data_extractorsで取り出した値が、その階層の入力データとなる' do
        extractors = [
          create_extractor(:foo, :fizz_0) { |d| d[0][0] },
          create_extractor(:bar, :fizz_1) { |d| d[0][0] },
          create_extractor(:baz, :fizz_2) { |d| d[0][0] },
          create_extractor(:foo, :buzz_0) { |d| d[0][1] },
          create_extractor(:bar, :buzz_1) { |d| d[0][1] },
          create_extractor(:baz, :buzz_2) { |d| d[0][1] }
        ]
        loader = loader_base.new(extractors, {})

        loader.load_file(file_name, input_data, valid_value_lists)
        expect(foo_data).to have_values([:fizz_0, :a], [:buzz_0, :b])
        expect(bar_data[0]).to have_values([:fizz_1, :c], [:buzz_1, :d])
        expect(baz_data[0]).to have_values([:fizz_2, :e], [:buzz_2, :f])
        expect(baz_data[1]).to have_values([:fizz_2, :g], [:buzz_2, :h])
        expect(bar_data[1]).to have_values([:fizz_1, :i], [:buzz_1, :j])
        expect(baz_data[2]).to have_values([:fizz_2, :k], [:buzz_2, :l])
        expect(baz_data[3]).to have_values([:fizz_2, :m], [:buzz_2, :n])
      end

      context 'input_data_extractorsが指定されていない値の場合' do
        specify '指定されていない値は設定されない' do
          extractors = [
            create_extractor(:foo, :fizz_0) { |d| d[0][0] }
          ]
          loader = loader_base.new(extractors, {})

          loader.load_file(file_name, input_data, valid_value_lists)
          expect(foo_data).to have_value(:fizz_0, :a)
          expect(foo_data).not_to have_value(:buzz_0)
        end
      end

      context 'input_data_extractorsがnilを返す場合' do
        specify '当該の値は設定されない' do
          extractors = [
            create_extractor(:foo, :fizz_0) { |d| d[0][0] },
            create_extractor(:foo, :buzz_0) {}
          ]
          loader = loader_base.new(extractors, {})

          loader.load_file(file_name, input_data, valid_value_lists)
          expect(foo_data).to have_value(:fizz_0, :a)
          expect(foo_data).not_to have_value(:buzz_0)
        end
      end

      context '同じ値に複数のinput_data_extractorが指定された場合' do
        specify '後に指定されたinput_data_extractorが優先される' do
          extractors = [
            create_extractor(:foo, :fizz_0) { |d| d[0][0] },
            create_extractor(:foo, :fizz_0) { |d| d[0][0].upcase }
          ]
          loader = loader_base.new(extractors, {})

          loader.load_file(file_name, input_data, valid_value_lists)
          expect(foo_data).to have_value(:fizz_0, :A)
        end
      end
    end

    context 'ignore_valuesが指定された場合' do
      let(:ignore_values) do
        { foo: [:fizz_0], bar: [:buzz_1], baz: [:fizz_2, :buzz_2]}
      end

      specify '指定された値は無視される' do
        loader = simple_loader.new([], ignore_values)
        loader.load_file(file_name, input_data, valid_value_lists)
        expect(foo_data).to have_value(:buzz_0, :b)
        expect(foo_data).not_to have_value(:fizz_0)
        expect(bar_data[0]).to have_value(:fizz_1, :c)
        expect(bar_data[0]).not_to have_value(:buzz_1, :d)
        expect(baz_data[0]).not_to have_values(:fizz_2)
        expect(baz_data[0]).not_to have_values(:buzz_2)
      end

      specify 'input_data_extractorによって抽出される値も対象' do
        extractors = [
          create_extractor(:foo, :fizz_0) { |d| d[0][0] },
          create_extractor(:bar, :fizz_1) { |d| d[0][0] },
          create_extractor(:baz, :fizz_2) { |d| d[0][0] },
          create_extractor(:foo, :buzz_0) { |d| d[0][1] },
          create_extractor(:bar, :buzz_1) { |d| d[0][1] },
          create_extractor(:baz, :buzz_2) { |d| d[0][1] }
        ]
        loader = loader_base.new(extractors, ignore_values)

        loader.load_file(file_name, input_data, valid_value_lists)
        expect(foo_data).to have_value(:buzz_0, :b)
        expect(foo_data).not_to have_value(:fizz_0)
        expect(bar_data[0]).to have_value(:fizz_1, :c)
        expect(bar_data[0]).not_to have_value(:buzz_1, :d)
        expect(baz_data[0]).not_to have_values(:fizz_2)
        expect(baz_data[0]).not_to have_values(:buzz_2)
      end
    end

    context 'ファイルが存在しない場合' do
      let(:invalid_file_name) { 'baz.rb' }

      before do
        allow(File).to receive(:readable?).with(invalid_file_name).and_return(false)
      end

      it 'LoadErrorを起こす' do
        expect {
          loader_base.new([], {}).load_file(invalid_file_name, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, 'cannot load such file', invalid_file_name
      end
    end
  end
end

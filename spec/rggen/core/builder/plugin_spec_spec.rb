# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::PluginSpec do
  let(:plugin_name) do
    :foo
  end

  let(:builder) do
    RgGen::Core::Builder::Builder.new
  end

  def create_spec(&body)
    described_class.new(plugin_name, &body)
  end

  describe '#version' do
    context '#versionでバージョンが指定された場合' do
      it '指定されたバージョンを返す' do
        spec = create_spec { |s| s.version '0.0.1' }
        expect(spec.version).to eq '0.0.1'
      end
    end

    context '上記２つを満たさない場合' do
      it 'デフォルトのバージョンとして0.0.0を返す' do
        spec = create_spec
        expect(spec.version).to eq '0.0.0'
      end
    end
  end

  describe '#version_info' do
    it 'プラグイン名込みのバージョン情報を返す' do
      spec = create_spec
      expect(spec.version_info).to eq "#{plugin_name} 0.0.0"
    end
  end

  describe '#register_component' do
    it '出力コンポーネントの登録を行う' do
      foo_registry = builder.output_component_registry(:foo)
      bar_registry = builder.output_component_registry(:bar)

      spec = create_spec do |s|
        s.register_component(:foo) {}
        s.register_component(:bar, :register_block)
        s.register_component(:bar, [:register, :bit_field])
      end

      expect(foo_registry).to receive(:register_component).with(be_nil)
      expect(bar_registry).to receive(:register_component).with(:register_block)
      expect(bar_registry).to receive(:register_component).with(match([:register, :bit_field]))
      spec.activate(builder)
    end
  end

  describe '#setup_loader' do
    it 'ローダーの登録を行う' do
      registries = [
        builder.input_component_registry(:register_map),
        builder.input_component_registry(:configuration)
      ]

      spec = create_spec do |s|
        s.setup_loader(:register_map, :foo) {}
        s.setup_loader(:configuration, :bar) {}
      end

      expect(registries[0]).to receive(:setup_loader).with(:foo)
      expect(registries[1]).to receive(:setup_loader).with(:bar)
      spec.activate(builder)
    end
  end

  describe '#files' do
    it '読み込むファイルを、パスを拡張したうえで、登録する' do
      spec = create_spec do |s|
        s.files ['foo.rb', 'bar/bar.rb']
        s.files ['baz/baz/baz.rb']
      end

      ['foo.rb', 'bar/bar.rb', 'baz/baz/baz.rb'].each do |path|
        expect(spec).to receive(:require).with(File.join(__dir__, path))
      end

      spec.activate(builder)
    end
  end

  describe '#addtional_setup' do
    specify '#activate_additionally実行時に、指定したブロックが実行される' do
      expect { |b|
        spec = create_spec { |s| s.addtional_setup(&b) }
        spec.activate_additionally(builder)
      }.to yield_with_args(equal(builder))
    end

    context 'ブロックの登録がない場合' do
      specify '#activate_additionallyをエラーなく実行できる' do
        expect {
          spec = create_spec
          spec.activate_additionally(builder)
        }.not_to raise_error
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::PluginSpec do
  let(:plugin_spec) do
    described_class.new(plugin_name, plugin_module)
  end

  let(:plugin_name) do
    :foo
  end

  let(:plugin_module) do
    Module.new
  end

  let(:builder) do
    RgGen::Core::Builder::Builder.new
  end

  describe '#version' do
    context '#versionでバージョンが指定された場合' do
      it '指定されたバージョンを返す' do
        plugin_spec.version '0.0.1'
        expect(plugin_spec.version).to eq '0.0.1'
      end
    end

    context 'プラグインモジュールが定数VERSIONを持つ場合' do
      it 'VERSIONを返す' do
        plugin_module.const_set(:VERSION, '0.0.1')
        expect(plugin_spec.version).to eq '0.0.1'
      end
    end

    context '上記２つを満たさない場合' do
      it 'デフォルトのバージョンとして0.0.0を返す' do
        expect(plugin_spec.version).to eq '0.0.0'
      end
    end
  end

  describe '#version_info' do
    it 'プラグイン名込みのバージョン情報を返す' do
      expect(plugin_spec.version_info).to eq "#{plugin_name} 0.0.0"
    end
  end

  describe '#register_component' do
    it '出力コンポーネントの登録を行う' do
      foo_registry = builder.output_component_registry(:foo)
      bar_registry = builder.output_component_registry(:bar)

      plugin_spec.register_component(:foo) {}
      plugin_spec.register_component(:bar, :register_block)
      plugin_spec.register_component(:bar, [:register, :bit_field])

      expect(foo_registry).to receive(:register_component).with(be_nil)
      expect(bar_registry).to receive(:register_component).with(:register_block)
      expect(bar_registry).to receive(:register_component).with(match([:register, :bit_field]))
      plugin_spec.activate(builder)
    end
  end

  describe '#register_loader/register_loaders' do
    let(:foo_loader) do
      Class.new(RgGen::Core::InputBase::Loader)
    end

    let(:bar_loader) do
      Class.new(RgGen::Core::InputBase::Loader)
    end

    let(:baz_loader) do
      Class.new(RgGen::Core::InputBase::Loader)
    end

    let(:qux_loader) do
      Class.new(RgGen::Core::InputBase::Loader)
    end

    it 'ローダーの登録を行う' do
      plugin_spec.register_loader(:register_map, :foo_bar, foo_loader)
      plugin_spec.register_loader(:register_map, :foo_bar, bar_loader)
      plugin_spec.register_loaders(:configuration, :baz_qux, [baz_loader, qux_loader])

      expect(builder).to receive(:register_loader).with(:register_map, :foo_bar, equal(foo_loader))
      expect(builder).to receive(:register_loader).with(:register_map, :foo_bar, equal(bar_loader))
      expect(builder).to receive(:register_loader).with(:configuration, :baz_qux, equal(baz_loader))
      expect(builder).to receive(:register_loader).with(:configuration, :baz_qux, equal(qux_loader))
      plugin_spec.activate(builder)
    end
  end

  describe '#files' do
    it '読み込むファイルを、パスを拡張したうえで、登録する' do
      plugin_spec.files [
        'foo.rb',
        'bar/bar.rb'
      ]
      plugin_spec.files [
        'baz/baz/baz.rb'
      ]

      ['foo.rb', 'bar/bar.rb', 'baz/baz/baz.rb'].each do |path|
        expect(plugin_spec).to receive(:require).with(File.join(__dir__, path))
      end

      plugin_spec.activate(builder)
    end
  end
end

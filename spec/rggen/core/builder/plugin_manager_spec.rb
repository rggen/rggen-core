# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::PluginManager do
  let(:builder) do
    RgGen::Core::Builder::Builder.new
  end

  let(:plugin_manager) do
    described_class.new(builder)
  end

  describe '#load_plugin' do
    context "'setup.rb'へのパスが指定された場合" do
      it '指定されたsetup.rbを読み込む' do
        expect(plugin_manager).to receive(:require).with('setup')
        plugin_manager.load_plugin('setup')

        expect(plugin_manager).to receive(:require).with('foo/setup')
        plugin_manager.load_plugin(' foo/setup')

        expect(plugin_manager).to receive(:require).with('foo/bar/setup')
        plugin_manager.load_plugin('foo/bar/setup ')
      end
    end

    context 'プラグイン名が指定された場合' do
      it "指定されたプラグイン名から'setup.rb'のパスを推定し、読み込む" do
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')
        plugin_manager.load_plugin('foo')

        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')
        plugin_manager.load_plugin('rggen-foo')

        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')
        plugin_manager.load_plugin('rggen_foo')

        expect(plugin_manager).to receive(:require).with('rggen/foo_bar/setup')
        plugin_manager.load_plugin('rggen-foo-bar')

        expect(plugin_manager).to receive(:require).with('rggen/foo_bar/setup')
        plugin_manager.load_plugin('rggen_foo_bar')
      end
    end

    context 'プラグイン名と下位ディレクトリが指定された場合' do
      it "指定されたプラグイン名と下位ディレクトリから'setup.rb'のパスを推定し、読み込む" do
        expect(plugin_manager).to receive(:require).with('rggen/foo/bar/setup')
        plugin_manager.load_plugin('foo', 'bar')

        expect(plugin_manager).to receive(:require).with('rggen/foo/bar/setup')
        plugin_manager.load_plugin('rggen-foo', 'bar')

        expect(plugin_manager).to receive(:require).with('rggen/foo/bar/setup')
        plugin_manager.load_plugin('rggen_foo', 'bar')

        expect(plugin_manager).to receive(:require).with('rggen/foo_bar/baz/setup')
        plugin_manager.load_plugin('rggen-foo-bar', 'baz')

        expect(plugin_manager).to receive(:require).with('rggen/foo_bar/baz/setup')
        plugin_manager.load_plugin('rggen_foo_bar', 'baz')
      end
    end

    context "指定された'setup.rb'が読み込めなかった場合" do
      it 'LoadErrorを起こす' do
        allow(plugin_manager).to receive(:require).with('foo/setup').and_raise(::LoadError)
        expect {
          plugin_manager.load_plugin('foo/setup')
        }.to raise_rggen_error RgGen::Core::LoadError, 'cannot load such plugin: foo/setup'

        allow(plugin_manager).to receive(:require).with('rggen/foo/setup').and_raise(::LoadError)
        expect {
          plugin_manager.load_plugin('rggen-foo')
        }.to raise_rggen_error RgGen::Core::LoadError, 'cannot load such plugin: rggen-foo (rggen/foo/setup)'

        allow(plugin_manager).to receive(:require).with('rggen/foo/bar/setup').and_raise(::LoadError)
        expect {
          plugin_manager.load_plugin('rggen-foo', 'bar')
        }.to raise_rggen_error RgGen::Core::LoadError, 'cannot load such plugin: rggen-foo (rggen/foo/bar/setup)'
      end
    end
  end

  describe '#load_plugins' do
    let(:default_plugins) do
      [
        ['rggen-default-register-map'],
        ['rggen-systemverilog', 'rtl'],
        ['rggen-systemverilog', 'ral'],
        ['rggen-markdown'],
        ['rggen-spreadsheet-loader']
      ]
    end

    before do
      allow(plugin_manager).to receive(:require).with('rggen/default_plugins') do
        RgGen.__send__(:const_set, :DEFAULT_PLUGINS, default_plugins)
      end
    end

    before do
      allow(ENV).to receive(:key?).with('RGGEN_NO_DEFAULT_PLUGINS').and_return(false)
      allow(ENV).to receive(:[]).with('RGGEN_PLUGINS').and_return(nil)
    end

    after do
      RgGen.module_eval do
        const_defined?(:DEFAULT_PLUGINS) && remove_const(:DEFAULT_PLUGINS)
      end
    end

    it 'DEFAULT_PLUGINSと引数で指定されたプラグインを読み込む' do
      expect(plugin_manager).to receive(:load_plugin).with('rggen-default-register-map').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/default_register_map/setup')

      expect(plugin_manager).to receive(:load_plugin).with('rggen-systemverilog', 'rtl').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/systemverilog/rtl/setup')

      expect(plugin_manager).to receive(:load_plugin).with('rggen-systemverilog', 'ral').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/systemverilog/ral/setup')

      expect(plugin_manager).to receive(:load_plugin).with('rggen-markdown').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/markdown/setup')

      expect(plugin_manager).to receive(:load_plugin).with('rggen-spreadsheet-loader').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/spreadsheet_loader/setup')

      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

      expect(plugin_manager).to receive(:load_plugin).with('rggen-bar', 'baz').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/bar/baz/setup')

      plugin_manager.load_plugins([['rggen-foo'], ['rggen-bar', 'baz']])
    end

    context 'rggen/default_pluginsが読み込めない場合' do
      it 'default_pluginsは読み込まない' do
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-default-register-map')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-systemverilog', 'rtl')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-systemverilog', 'ral')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-markdown')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-spreadsheet-loader')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-bar', 'baz').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/bar/baz/setup')

        allow(plugin_manager).to receive(:require).with('rggen/default_plugins').and_raise(::LoadError)
        plugin_manager.load_plugins([['rggen-foo'], ['rggen-bar', 'baz']])
      end
    end

    context '環境変数RGGEN_NO_DEFAULT_PLUGINSが設定されている場合' do
      it 'default_pluginsは読み込まない' do
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-default-register-map')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-systemverilog', 'rtl')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-systemverilog', 'ral')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-markdown')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-spreadsheet-loader')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-bar', 'baz').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/bar/baz/setup')

        allow(ENV).to receive(:key?).with('RGGEN_NO_DEFAULT_PLUGINS').and_return(true)
        plugin_manager.load_plugins([['rggen-foo'], ['rggen-bar', 'baz']])
      end
    end

    context '引数no_default_pluginにtrueが指定された場合' do
      it 'default_pluginsは読み込まない' do
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-default-register-map')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-systemverilog', 'rtl')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-systemverilog', 'ral')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-markdown')
        expect(plugin_manager).not_to receive(:load_plugin).with('rggen-spreadsheet-loader')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-bar', 'baz').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/bar/baz/setup')

        plugin_manager.load_plugins([['rggen-foo'], ['rggen-bar', 'baz']], true)
      end
    end

    context '環境変数RGGEN_PLUGINSが設定されている場合' do
      it 'RGGEN_PLUGINSで指定されたプラグインも追加で読み込む' do
        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        expect(plugin_manager).to receive(:load_plugin).with('bar/setup').and_call_original
        expect(plugin_manager).to receive(:require).with('bar/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-baz', 'qux').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/baz/qux/setup')

        allow(ENV).to receive(:[]).with('RGGEN_PLUGINS').and_return('bar/setup:rggen-baz,qux')
        plugin_manager.load_plugins([['rggen-foo']], true)
      end
    end
  end

  describe '#setup' do
    before(:all) do
      module Foo
        VERSION = '0.0.1'
        def self.default_setup(_builder); end
      end

      module Bar
        def self.version; '0.0.2'; end
        def self.default_setup(_builder); end
      end

      module Baz
      end
    end

    after(:all) do
      Object.instance_eval do
        remove_const :Foo
        remove_const :Bar
        remove_const :Baz
      end
    end

    context 'モジュールが指定されて、.default_setupが実装されている場合' do
      specify '#activate_plugins実行時に、.default_setupを実行し、既定のセットアップを行う' do
        expect(Foo).to receive(:default_setup).with(equal(builder))
        expect(Bar).to receive(:default_setup).with(equal(builder))
        plugin_manager.setup(:foo, Foo)
        plugin_manager.setup(:bar, Bar)
        plugin_manager.activate_plugins
      end
    end

    context 'モジュールが指定されて、.default_setupが実装されていない場合' do
      specify 'エラーなくプラグインの追加を実行できる' do
        expect {
          plugin_manager.setup(:baz, Baz)
          plugin_manager.activate_plugins
        }.not_to raise_error
      end
    end

    context 'ブロックが与えられた場合' do
      specify '#activate_plugins実行時に、指定されたモジュール上でブロックを実行する' do
        plugin_manager.setup(:foo, Foo) { |b| do_setup(b) }
        plugin_manager.setup(:baz, Baz) { |b| do_setup(b) }
        expect(Foo).to receive(:do_setup).with(equal(builder))
        expect(Baz).to receive(:do_setup).with(equal(builder))
        plugin_manager.activate_plugins
      end

      specify '.default_setup実行後に、ブロックが実行される' do
        block = proc do
          expect(Foo).to have_received(:default_setup)
          expect(Bar).to have_received(:default_setup)
        end
        plugin_manager.setup(:foo, Foo) { block.call }
        plugin_manager.setup(:bar, Bar)

        allow(Foo).to receive(:default_setup)
        allow(Bar).to receive(:default_setup)
        plugin_manager.activate_plugins
      end
    end

    describe 'バージョン情報の収集' do
      context '指定されたモジュールが、定数VERSIONを持つ場合' do
        specify 'VERSIONで指定されたバージョンがプラグインのバージョンとする' do
          plugin_manager.setup(:foo, Foo)
          expect(plugin_manager.version_info[0]).to eq "foo #{Foo::VERSION}"
        end
      end

      context '指定されたモジュールが、メソッド.versionを持つ場合' do
        specify '.versionの戻り値をプラグインのバージョンとする' do
          plugin_manager.setup(:bar, Bar)
          expect(plugin_manager.version_info[0]).to eq "bar #{Bar.version}"
        end
      end

      context '指定されたモジュールに、VERSIONも.versionもない場合' do
        specify '規定バージョン0.0.0をプラグインのバージョンとする' do
          plugin_manager.setup(:baz, Baz)
          expect(plugin_manager.version_info[0]).to eq 'baz 0.0.0'
        end
      end

      specify '#version_infoでプラグインのバージョン一覧を取得できる' do
        plugin_manager.setup(:foo, Foo)
        plugin_manager.setup(:bar, Bar)
        plugin_manager.setup(:baz, Baz)
        expect(plugin_manager.version_info).to match([
          "foo #{Foo::VERSION}", "bar #{Bar.version}", 'baz 0.0.0'
        ])
      end
    end
  end
end

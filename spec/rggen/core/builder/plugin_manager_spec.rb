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

        expect(plugin_manager).to receive(:require).with('setup.rb')
        plugin_manager.load_plugin('setup.rb')

        expect(plugin_manager).to receive(:require).with('foo.rb')
        plugin_manager.load_plugin('foo.rb')

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
        plugin_manager.load_plugin(:foo)

        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')
        plugin_manager.load_plugin('rggen-foo')

        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')
        plugin_manager.load_plugin(:'rggen-foo')

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
        plugin_manager.load_plugin('foo/bar')

        expect(plugin_manager).to receive(:require).with('rggen/foo/bar/setup')
        plugin_manager.load_plugin('rggen-foo/bar')

        expect(plugin_manager).to receive(:require).with('rggen/foo/bar/setup')
        plugin_manager.load_plugin('rggen_foo/bar')

        expect(plugin_manager).to receive(:require).with('rggen/foo_bar/baz/setup')
        plugin_manager.load_plugin('rggen-foo-bar/baz')

        expect(plugin_manager).to receive(:require).with('rggen/foo_bar/baz/setup')
        plugin_manager.load_plugin('rggen_foo_bar/baz')

        expect(plugin_manager).to receive(:require).with('rggen/foo/bar/baz/setup')
        plugin_manager.load_plugin('rggen-foo/bar/baz')

        expect(plugin_manager).to receive(:require).with('rggen/foo/bar/baz/setup')
        plugin_manager.load_plugin('rggen_foo/bar/baz')

        expect(plugin_manager).to receive(:require).with('rggen/foo/bar-baz/setup')
        plugin_manager.load_plugin('rggen-foo/bar-baz')

        expect(plugin_manager).to receive(:require).with('rggen/foo/bar-baz/setup')
        plugin_manager.load_plugin('rggen_foo/bar-baz')
      end
    end

    context "指定された'setup.rb'が読み込めなかった場合" do
      it 'PluginErrorを起こす' do
        allow(plugin_manager).to receive(:require).with('foo/setup').and_raise(::LoadError)
        expect {
          plugin_manager.load_plugin('foo/setup')
        }.to raise_rggen_error RgGen::Core::PluginError, 'cannot load such plugin: foo/setup'

        allow(plugin_manager).to receive(:require).with('rggen/foo/setup').and_raise(::LoadError)
        expect {
          plugin_manager.load_plugin('rggen-foo')
        }.to raise_rggen_error RgGen::Core::PluginError, 'cannot load such plugin: rggen-foo (rggen/foo/setup)'

        allow(plugin_manager).to receive(:require).with('rggen/foo/bar/setup').and_raise(::LoadError)
        expect {
          plugin_manager.load_plugin('rggen-foo/bar')
        }.to raise_rggen_error RgGen::Core::PluginError, 'cannot load such plugin: rggen-foo/bar (rggen/foo/bar/setup)'
      end
    end
  end

  describe '#load_plugins' do
    let(:default_plugins) do
      'rggen/setup'
    end

    before do
      allow(Gem).to receive(:find_files).with(default_plugins).and_return([default_plugins])
    end

    before do
      allow(ENV).to receive(:key?).with('RGGEN_NO_DEFAULT_PLUGINS').and_return(false)
      allow(ENV).to receive(:[]).with('RGGEN_PLUGINS').and_return(nil)
    end

    it 'プラグインの読み込み前に、RgGen.builderに@builderを設定する' do
      expect(RgGen).to receive(:builder).with(equal(builder)).ordered
      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').ordered
      plugin_manager.load_plugins(['rggen-foo'], true)
    end

    it '既定プラグインと引数で指定されたプラグインを読み込む' do
      expect(plugin_manager).to receive(:load_plugin).with(default_plugins).and_call_original
      expect(plugin_manager).to receive(:require).with(default_plugins)

      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

      expect(plugin_manager).to receive(:load_plugin).with('rggen-bar/baz').and_call_original
      expect(plugin_manager).to receive(:require).with('rggen/bar/baz/setup')

      plugin_manager.load_plugins(['rggen-foo', 'rggen-bar/baz'], false)
    end

    it 'プラグイン読み込み後、プラグインの有効化を行う' do
      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').ordered
      expect(plugin_manager).to receive(:load_plugin).with('rggen-bar').ordered
      expect(plugin_manager).to receive(:activate_plugins).ordered
      plugin_manager.load_plugins(['rggen-foo', 'rggen-bar'], true)
    end

    context '\'rggen/setup\'が読み込めない場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)

        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-bar/baz').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/bar/baz/setup')

        allow(Gem).to receive(:find_files).with(default_plugins).and_return([])
        plugin_manager.load_plugins(['rggen-foo', 'rggen-bar/baz'], false)
      end
    end

    context '環境変数RGGEN_NO_DEFAULT_PLUGINSが設定されている場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)

        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-bar/baz').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/bar/baz/setup')

        allow(ENV).to receive(:key?).with('RGGEN_NO_DEFAULT_PLUGINS').and_return(true)
        plugin_manager.load_plugins(['rggen-foo', 'rggen-bar/baz'], false)
      end
    end

    context '引数no_default_pluginにtrueが指定された場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)

        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-bar/baz').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/bar/baz/setup')

        plugin_manager.load_plugins(['rggen-foo', 'rggen-bar/baz'], true)
      end
    end

    context '環境変数RGGEN_PLUGINSが設定されている場合' do
      it 'RGGEN_PLUGINSで指定されたプラグインも追加で読み込む' do
        expect(plugin_manager).to receive(:load_plugin).with('bar/setup').and_call_original
        expect(plugin_manager).to receive(:require).with('bar/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-baz/qux/foobar').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/baz/qux/foobar/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        allow(ENV).to receive(:[]).with('RGGEN_PLUGINS').and_return('bar/setup:rggen-baz/qux/foobar')
        plugin_manager.load_plugins(['rggen-foo'], true)

        expect(plugin_manager).to receive(:load_plugin).with('bar/setup').and_call_original
        expect(plugin_manager).to receive(:require).with('bar/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-baz/qux/foobar').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/baz/qux/foobar/setup')

        expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').and_call_original
        expect(plugin_manager).to receive(:require).with('rggen/foo/setup')

        allow(ENV).to receive(:[]).with('RGGEN_PLUGINS').and_return(' : bar/setup : rggen-baz/qux/foobar')
        plugin_manager.load_plugins(['rggen-foo'], true)
      end
    end

    context 'activationにfalseが指定された場合' do
      it 'プラグインの有効化は行わない' do
        allow(plugin_manager).to receive(:load_plugin).with('rggen-foo')
        expect(plugin_manager).not_to receive(:activate_plugins)
        plugin_manager.load_plugins(['rggen-foo'], true, false)
      end
    end
  end

  describe '#register_plugin' do
    before(:all) do
      module Foo
        extend RgGen::Core::Plugin

        VERSION = '0.0.1'
        setup_plugin 'foo'
      end

      module Bar
        extend RgGen::Core::Plugin

        def self.version
          '0.0.2'
        end

        setup_plugin 'bar' do |plugin|
          plugin.version version
        end
      end

      module Baz
        extend RgGen::Core::Plugin
      end

      module Qux
      end
    end

    after(:all) do
      Object.instance_eval do
        remove_const :Foo
        remove_const :Bar
        remove_const :Baz
        remove_const :Qux
      end
    end

    context '指定されたモジュールが.plugin_specを持つ場合' do
      specify '#activate_plugins実行時に、.plugin_spec.activateを実行し、プラグインの設定を行う' do
        plugin_manager.register_plugin(Foo)
        plugin_manager.register_plugin(Bar)

        expect(Foo.plugin_spec).to receive(:activate).with(equal(builder))
        expect(Bar.plugin_spec).to receive(:activate).with(equal(builder))

        plugin_manager.activate_plugins
      end
    end

    context '指定されたモジュールが.plugin_specを持たない場合' do
      it 'PluginErrorを起こす' do
        expect {
          plugin_manager.register_plugin(Baz)
        }.to raise_rggen_error RgGen::Core::PluginError, 'no plugin spec is given'

        expect {
          plugin_manager.register_plugin(Qux)
        }.to raise_rggen_error RgGen::Core::PluginError, 'no plugin spec is given'
      end
    end

    context 'ブロックが与えられた場合' do
      specify '#activate_plugins実行時に、指定されたモジュール上でブロックを実行する' do
        plugin_manager.register_plugin(Foo) { |b| do_setup(b) }
        plugin_manager.register_plugin(Bar) { |b| do_setup(b) }
        expect(Foo).to receive(:do_setup).with(equal(builder))
        expect(Bar).to receive(:do_setup).with(equal(builder))
        plugin_manager.activate_plugins
      end

      specify '.plugin_spec.activate実行後に、ブロックが実行される' do
        block = proc do
          expect(Foo.plugin_spec).to have_received(:activate)
          expect(Bar.plugin_spec).to have_received(:activate)
        end
        plugin_manager.register_plugin(Foo) { block.call }
        plugin_manager.register_plugin(Bar)

        allow(Foo.plugin_spec).to receive(:activate)
        allow(Bar.plugin_spec).to receive(:activate)
        plugin_manager.activate_plugins
      end
    end

    describe 'バージョン情報の収集' do
      specify '#version_infoでプラグインのバージョン一覧を取得できる' do
        plugin_manager.register_plugin(Foo)
        plugin_manager.register_plugin(Bar)
        expect(plugin_manager.version_info).to match([
          "foo #{Foo::VERSION}",
          "bar #{Bar.version}"
        ])
      end
    end
  end
end

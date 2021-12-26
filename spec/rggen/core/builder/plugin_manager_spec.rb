# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::PluginManager do
  def expand_setup_path(setup_file)
    base = File.join(RGGEN_CORE_ROOT, 'spec', 'dummy_plugins')
    Dir
      .glob(File.join('**', setup_file), base: base)
      .map { |path| File.join(base, path) }
      .first
  end

  def setup_plugin_expectation(**args)
    plugin = args[:plugin]
    version = args.key?(:version) && match_string(args[:version]) || nil
    setup_file = args[:setup_file]
    if plugin
      expect(plugin_manager).to receive(:gem).with(plugin, version)
    end
    if setup_file
      expect(plugin_manager).to receive(:require).with(setup_file)
    end
  end

  let(:builder) do
    RgGen::Core::Builder::Builder.new
  end

  let(:plugin_manager) do
    described_class.new(builder)
  end

  describe '#load_plugin' do
    before do
      allow(plugin_manager).to receive(:require)
    end

    context "'setup.rb'へのパスが指定された場合" do
      it '指定されたsetup.rbを読み込む' do
        setup_plugin_expectation(setup_file: 'setup')
        plugin_manager.load_plugin('setup')

        setup_plugin_expectation(setup_file: 'setup.rb')
        plugin_manager.load_plugin('setup.rb')

        setup_plugin_expectation(setup_file: 'foo.rb')
        plugin_manager.load_plugin('foo.rb')

        setup_plugin_expectation(setup_file: 'foo/setup')
        plugin_manager.load_plugin(' foo/setup')

        setup_plugin_expectation(setup_file: 'foo/bar/setup')
        plugin_manager.load_plugin('foo/bar/setup ')
      end

      context 'Gemとして管理されているプラグインのsetup.rbが指定された場合' do
        it '当該Gemを有効にし、指定されたsetup.rbを読み込む' do
          setup_file = expand_setup_path('rggen/foo/setup.rb')
          setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', setup_file: setup_file)
          plugin_manager.load_plugin(setup_file)

          setup_file = expand_setup_path('rggen/foo/bar/baz/setup.rb')
          setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', setup_file: setup_file)
          plugin_manager.load_plugin(setup_file)

          setup_file = expand_setup_path('rggen/foo_bar/setup.rb')
          setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: setup_file)
          plugin_manager.load_plugin(setup_file)

          setup_file = expand_setup_path('rggen/foo_bar/baz/setup.rb')
          setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: setup_file)
          plugin_manager.load_plugin(setup_file)
        end
      end
    end

    context 'プラグイン名が指定された場合' do
      it "指定されたプラグイン名から'setup.rb'のパスを推定し、読み込む" do
        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/setup')
        plugin_manager.load_plugin('rggen-foo')

        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/setup')
        plugin_manager.load_plugin(:'rggen-foo')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', setup_file: 'rggen/foo/setup')
        plugin_manager.load_plugin('rggen-foo', '0.1.0')

        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: 'rggen/foo_bar/setup')
        plugin_manager.load_plugin('rggen-foo-bar', '0.2.0')
      end
    end

    context 'プラグイン名と下位ディレクトリが指定された場合' do
      it "指定されたプラグイン名と下位ディレクトリから'setup.rb'のパスを推定し、読み込む" do
        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/bar/setup')
        plugin_manager.load_plugin('rggen-foo/bar')

        setup_plugin_expectation(plugin: 'rggen-foo-bar', setup_file: 'rggen/foo_bar/baz/setup')
        plugin_manager.load_plugin('rggen-foo-bar/baz')

        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/bar/baz/setup')
        plugin_manager.load_plugin('rggen-foo/bar/baz')

        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/bar_baz/setup')
        plugin_manager.load_plugin('rggen-foo/bar_baz')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', setup_file: 'rggen/foo/bar/setup')
        plugin_manager.load_plugin('rggen-foo/bar', '0.1.0')

        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: 'rggen/foo_bar/baz/setup')
        plugin_manager.load_plugin('rggen-foo-bar/baz', '0.2.0')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', setup_file: 'rggen/foo/bar/baz/setup')
        plugin_manager.load_plugin('rggen-foo/bar/baz', '0.1.0')

        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: 'rggen/foo_bar/baz/setup')
        plugin_manager.load_plugin('rggen-foo-bar/baz', '0.2.0')
      end
    end

    context "指定されたプラグインが読み込めなかった場合" do
      it 'PluginErrorを起こす' do
        allow(plugin_manager).to receive(:require).with('foo/setup').and_raise(::LoadError)
        expect {
          plugin_manager.load_plugin('foo/setup')
        }.to raise_rggen_error RgGen::Core::PluginError, 'cannot load such plugin: foo/setup'

        expect {
          plugin_manager.load_plugin('rggen-bar')
        }.to raise_rggen_error RgGen::Core::PluginError, 'cannot load such plugin: rggen-bar'

        expect {
          plugin_manager.load_plugin('rggen-bar/baz')
        }.to raise_rggen_error RgGen::Core::PluginError, 'cannot load such plugin: rggen-bar/baz'

        expect {
          plugin_manager.load_plugin('rggen-foo', '0.2.0')
        }.to raise_rggen_error RgGen::Core::PluginError, 'cannot load such plugin: rggen-foo (0.2.0)'
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
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('RGGEN_PLUGINS').and_return(nil)
    end

    before do
      allow(plugin_manager).to receive(:load_plugin).and_call_original
    end

    it 'プラグインの読み込み前に、RgGen.builderに@builderを設定する' do
      expect(RgGen).to receive(:builder).with(equal(builder)).ordered
      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').ordered
      plugin_manager.load_plugins(['rggen-foo'], true)
    end

    it '既定プラグインと引数で指定されたプラグインを読み込む' do
      setup_plugin_expectation(setup_file: default_plugins)
      setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/setup')
      setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: 'rggen/foo_bar/baz/setup')
      plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], false)
    end

    it 'プラグイン読み込み後、プラグインの有効化を行う' do
      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').ordered
      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo-bar').ordered
      expect(plugin_manager).to receive(:activate_plugins).ordered
      plugin_manager.load_plugins(['rggen-foo', 'rggen-foo-bar'], true)
    end

    context '\'rggen/setup\'が読み込めない場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)
        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/setup')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: 'rggen/foo_bar/baz/setup')

        allow(Gem).to receive(:find_files).with(default_plugins).and_return([])
        plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], false)
      end
    end

    context '環境変数RGGEN_NO_DEFAULT_PLUGINSが設定されている場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)
        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/setup')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: 'rggen/foo_bar/baz/setup')

        allow(ENV).to receive(:key?).with('RGGEN_NO_DEFAULT_PLUGINS').and_return(true)
        plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], false)
      end
    end

    context '引数no_default_pluginにtrueが指定された場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)
        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/setup')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: 'rggen/foo_bar/baz/setup')

        plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], true)
      end
    end

    context '環境変数RGGEN_PLUGINSが設定されている場合' do
      it 'RGGEN_PLUGINSで指定されたプラグインも追加で読み込む' do
        plugins = [
          'rggen-foo/bar,0.1.0',
          expand_setup_path('rggen/foo_bar/setup.rb')
        ]

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', setup_file: 'rggen/foo/bar/setup')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: plugins[1])
        setup_plugin_expectation(plugin: 'rggen-foo', setup_file: 'rggen/foo/setup')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', setup_file: 'rggen/foo_bar/baz/setup')

        allow(ENV).to receive(:[]).with('RGGEN_PLUGINS').and_return(plugins.join(':'))
        plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], true)
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

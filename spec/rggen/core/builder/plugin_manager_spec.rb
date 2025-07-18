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
    path = args[:path]
    if plugin
      expect(plugin_manager).to receive(:gem).with(plugin, version)
    end
    if path
      expect(plugin_manager).to receive(:require).with(path)
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

    context "プラグインへのパスが指定された場合" do
      it '指定されたプラグインを読み込む' do
        setup_plugin_expectation(path: 'foo.rb')
        plugin_manager.load_plugin('foo.rb')

        setup_plugin_expectation(path: 'foo.rb')
        plugin_manager.load_plugin('foo.rb')

        setup_plugin_expectation(path: 'foo/bar.rb')
        plugin_manager.load_plugin(' foo/bar.rb')

        setup_plugin_expectation(path: 'foo/bar/baz.rb')
        plugin_manager.load_plugin('foo/bar/baz.rb ')
      end

      context 'Gemとして管理されているプラグインのパスが指定された場合' do
        it '当該Gemを有効にし、指定されたプラグインを読み込む' do
          plugin_file = expand_setup_path('rggen/foo.rb')
          setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: plugin_file)
          plugin_manager.load_plugin(plugin_file)

          plugin_file = expand_setup_path('rggen/foo/bar/baz.rb')
          setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: plugin_file)
          plugin_manager.load_plugin(plugin_file)

          plugin_file = expand_setup_path('rggen/foo_bar.rb')
          setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: plugin_file)
          plugin_manager.load_plugin(plugin_file)

          plugin_file = expand_setup_path('rggen/foo_bar/baz.rb')
          setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: plugin_file)
          plugin_manager.load_plugin(plugin_file)
        end
      end
    end

    context 'プラグイン名が指定された場合' do
      it '指定されたプラグイン名からファイル名を推定し、読み込む' do
        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo')
        plugin_manager.load_plugin('rggen-foo')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo')
        plugin_manager.load_plugin(:'rggen-foo')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo')
        plugin_manager.load_plugin('rggen-foo', '0.1.0')

        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar')
        plugin_manager.load_plugin('rggen-foo-bar', '0.2.0')
      end
    end

    context 'プラグイン名と下位ディレクトリが指定された場合' do
      it '指定されたプラグイン名と下位ディレクトリからファイル名を推定し、読み込む' do
        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo/bar')
        plugin_manager.load_plugin('rggen-foo/bar')

        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar/baz')
        plugin_manager.load_plugin('rggen-foo-bar/baz')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo/bar/baz')
        plugin_manager.load_plugin('rggen-foo/bar/baz')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo/bar_baz')
        plugin_manager.load_plugin('rggen-foo/bar_baz')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo/bar')
        plugin_manager.load_plugin('rggen-foo/bar', '0.1.0')

        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar/baz')
        plugin_manager.load_plugin('rggen-foo-bar/baz', '0.2.0')

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo/bar/baz')
        plugin_manager.load_plugin('rggen-foo/bar/baz', '0.1.0')

        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar/baz')
        plugin_manager.load_plugin('rggen-foo-bar/baz', '0.2.0')
      end
    end

    context "指定されたプラグインが読み込めなかった場合" do
      it 'PluginErrorを起こす' do
        allow(plugin_manager).to receive(:require).with('foo').and_raise(::LoadError)
        expect {
          plugin_manager.load_plugin('foo')
        }.to raise_rggen_error RgGen::Core::PluginError, 'cannot load such plugin: foo'

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
      'rggen/default'
    end

    before do
      allow(ENV).to receive(:key?).with('RGGEN_NO_DEFAULT_PLUGINS').and_return(false)
      allow(ENV).to receive(:key?).with('RGGEN_PLUGINS').and_return(false)
      allow(ENV).to receive(:[]).and_call_original
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
      setup_plugin_expectation(plugin: 'rggen', path: default_plugins, version: RgGen::Core::VERSION)
      setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo')
      setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar/baz')
      plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], false)
    end

    it 'プラグイン読み込み後、プラグインの有効化を行う' do
      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo').ordered
      expect(plugin_manager).to receive(:load_plugin).with('rggen-foo-bar').ordered
      expect(plugin_manager).to receive(:activate_plugins).ordered
      plugin_manager.load_plugins(['rggen-foo', 'rggen-foo-bar'], true)
    end

    context 'rggen/defaultが読み込めない場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)
        setup_plugin_expectation(plugin: 'rggen-foo', path: 'rggen/foo', version: '0.1.0')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar/baz')

        allow(Gem::Specification).to receive(:find_all_by_name).and_call_original
        allow(Gem::Specification).to receive(:find_all_by_name).with('rggen', anything).and_return([])
        plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], false)
      end
    end

    context '環境変数RGGEN_NO_DEFAULT_PLUGINSが設定されている場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)
        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar/baz')

        allow(ENV).to receive(:key?).with('RGGEN_NO_DEFAULT_PLUGINS').and_return(true)
        plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], false)
      end
    end

    context '引数no_default_pluginにtrueが指定された場合' do
      it '既定プラグインは読み込まない' do
        expect(plugin_manager).to_not receive(:load_plugin).with(default_plugins)
        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar/baz')

        plugin_manager.load_plugins(['rggen-foo', ['rggen-foo-bar/baz', '0.2.0']], true)
      end
    end

    context '環境変数RGGEN_PLUGINSが設定されている場合' do
      it 'RGGEN_PLUGINSで指定されたプラグインも追加で読み込む' do
        plugins = [
          'rggen-foo/bar,0.1.0',
          expand_setup_path('rggen/foo_bar.rb')
        ]

        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo/bar')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: plugins[1])
        setup_plugin_expectation(plugin: 'rggen-foo', version: '0.1.0', path: 'rggen/foo')
        setup_plugin_expectation(plugin: 'rggen-foo-bar', version: '0.2.0', path: 'rggen/foo_bar/baz')

        allow(ENV).to receive(:key?).with('RGGEN_PLUGINS').and_return(true)
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

  describe '#setup_plugin' do
    let(:plugins) do
      []
    end

    before do
      list = plugins
      plugin_manager.setup_plugin(:foo) { |plugin| list << plugin; plugin.version '0.1.0' }
      plugin_manager.setup_plugin(:bar) { |plugin| list << plugin; plugin.version '0.2.0' }
    end

    specify '#activate_plugins実行時に、各プラグインの有効化を行う' do
      expect(plugins[0]).to receive(:activate).with(equal(builder)).ordered
      expect(plugins[1]).to receive(:activate).with(equal(builder)).ordered
      expect(plugins[0]).to receive(:activate_additionally).with(equal(builder)).ordered
      expect(plugins[1]).to receive(:activate_additionally).with(equal(builder)).ordered
      plugin_manager.activate_plugins
    end

    specify '#activate_plugin_by_name実行時に指定したプラグインの有効化を行う' do
      expect(plugins[0]).to receive(:activate).with(equal(builder)).ordered
      expect(plugins[0]).to receive(:activate_additionally).with(equal(builder)).ordered
      expect(plugins[1]).not_to receive(:activate)
      expect(plugins[1]).not_to receive(:activate_additionally)
      plugin_manager.activate_plugin_by_name(:foo)
    end

    describe 'バージョン情報の収集' do
      specify '#version_infoでプラグインのバージョン一覧を取得できる' do
        expect(plugin_manager.version_info).to match([
          'foo 0.1.0',
          'bar 0.2.0'
        ])
      end
    end
  end

  describe '#update_plugin' do
    it '指定されたプラグインを更新する' do
      plugin = nil
      plugin_manager.setup_plugin(:foo) { plugin = _1 }

      expect { |b| plugin_manager.update_plugin(:foo, &b) }
        .to yield_with_args(equal(plugin))
    end

    context '指定されたプラグインが未定義の場合' do
      it 'PluginErrorを起こす' do
        plugin_manager.setup_plugin(:foo) {}
        expect { plugin_manager.update_plugin(:bar) }
          .to raise_rggen_error RgGen::Core::PluginError, 'unknown plugin: bar'
      end
    end
  end
end

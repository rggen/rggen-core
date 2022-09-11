# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core
  describe Options do
    let(:options) { Options.new }

    before do
      allow_any_instance_of(Options::Option).to receive(:require).with('rggen/default_setup_file').and_raise(::LoadError)
      allow(ENV).to receive(:[]).with('RGGEN_DEFAULT_SETUP_FILE').and_return(nil)
      allow(ENV).to receive(:[]).with('RGGEN_DEFAULT_CONFIGURATION_FILE').and_return(nil)
    end

    describe '#register_map_files' do
      it 'パース後の残りの引数を返す' do
        original_args = [
          '-c', 'configuration.yaml', 'register_map_0.xlsx', 'register_map_1.xlsx'
        ]
        options.parse(original_args)
        expect(options.register_map_files).to match(['register_map_0.xlsx', 'register_map_1.xlsx'])
      end
    end

    describe 'no-default-pluginsオプション' do
      context '--no-default-pluginsが指定された場合' do
        it 'trueを返す' do
          options.parse(['--no-default-plugins'])
          expect(options[:no_default_plugins]).to be true
        end
      end

      context '--no-default-pluginsが未指定の場合' do
        it 'falseを返す' do
          options.parse([])
          expect(options[:no_default_plugins]).to be false
        end
      end
    end

    describe 'pluginオプション' do
      let(:plugins) do
        [['foo/setup'], ['rggen-bar'], ['rggen-buz/qux'], ['rggen-foo-bar', '0.1.0']].shuffle
      end

      let(:plugin_args) do
        plugins.map { |plugin| Array(plugin).join(':') }
      end

      context '--pluginが引数で指定された場合' do
        it 'オプションで指定されたプラグインを返す' do
          options.parse([
            '--plugin', plugin_args[0],
            '--plugin', plugin_args[1],
            '--plugin', plugin_args[2],
            '--plugin', plugin_args[3]
          ])
          expect(options[:plugins]).to match(plugins)
        end
      end

      context '--pluginオプションが未指定の場合' do
        it '空の配列を返す' do
          options.parse([])
          expect(options[:plugins]).to be_instance_of(Array).and be_empty
        end
      end
    end

    describe 'configurationオプション' do
      let(:configuration_files) do
        ['/foo/bar.yaml', '/foo/bar.json'].shuffle
      end

      context '-c/--configurationが引数で与えられた場合' do
        it 'オプションで指定されたファイルのパスを返す' do
          options.parse(['-c', configuration_files[0]])
          expect(options[:configuration]).to eq configuration_files[0]

          options.parse(['--configuration', configuration_files[1]])
          expect(options[:configuration]).to eq configuration_files[1]
        end
      end

      context '-c/--configurationが未指定で' do
        context '環境変数RGGEN_DEFAULT_CONFIGURATION_FILEが定義されている場合' do
          let(:configuration_file) { configuration_files.sample }

          before do
            allow(ENV).to receive(:fetch).with('RGGEN_DEFAULT_CONFIGURATION_FILE', nil).and_return(configuration_file)
          end

          it '当該環境変数で指定されたファイルのパスを返す' do
            options.parse([])
            expect(options[:configuration]).to eq configuration_file
          end
        end

        context '環境変数RGGEN_DEFAULT_CONFIGURATION_FILEが未指定の場合' do
          it 'nilを返す' do
            options.parse([])
            expect(options[:configuration]).to be nil
          end
        end
      end
    end

    describe 'outputオプション' do
      context '-o/--outputが引数で指定された場合' do
        let(:output_directories) do
          ['foo', '/bar/baz'].shuffle
        end

        it '指定された出力ディレクトリを返す' do
          options.parse(['-o', output_directories[0]])
          expect(options[:output]).to eq output_directories[0]

          options.parse(['--output', output_directories[1]])
          expect(options[:output]).to eq output_directories[1]
        end
      end

      context '-o/--outputが未指定の場合' do
        it '\'.\'を返す' do
          options.parse([])
          expect(options[:output]).to eq '.'
        end
      end
    end

    describe 'load-onlyオプション' do
      context '--load-onlyが引数で指定された場合' do
        it 'trueを返す' do
          options.parse(['--load-only'])
          expect(options[:load_only]).to be true
        end
      end

      context '--load-onlyが未指定の場合' do
        it 'falseを返す' do
          options.parse([])
          expect(options[:load_only]).to be false
        end
      end
    end

    describe 'enableオプション' do
      context '--enableが引数で指定された場合' do
        let(:targets) { ['foo', 'bar', 'baz'] }

        it '指定された対象生成物を配列で返す' do
          options.parse(['--enable', targets[0], '--enable', "#{targets[1]},#{targets[2]}"])
          expect(options[:enable]).to match(targets.map(&:to_sym))
        end
      end

      context '--enableが未指定の場合' do
        it '空の配列を返す' do
          options.parse([])
          expect(options[:enable]).to be_instance_of(Array).and be_empty
        end
      end
    end

    describe '--print-verbose-infoオプション' do
      context '--print-verbose-infoが指定された場合' do
        it 'trueを返す' do
          options.parse(['--print-verbose-info'])
          expect(options[:print_verbose_info]).to be true
        end
      end

      context '未指定の場合' do
        it 'falseを返す' do
          options.parse([])
          expect(options[:print_verbose_info]).to be false
        end
      end
    end

    describe '--print-backtraceオプション' do
      context '--print-backtraceが指定された場合' do
        it 'trueを返す' do
          options.parse(['--print-backtrace'])
          expect(options[:print_backtrace]).to be true
        end
      end

      context '未指定の場合' do
        it 'falseを返す' do
          options.parse([])
          expect(options[:print_backtrace]).to be false
        end
      end
    end
  end
end

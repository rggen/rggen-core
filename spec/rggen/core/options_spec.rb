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

    describe "#register_map_files" do
      it "パース後の残りの引数を返す" do
        original_args = [
          '-s', 'setup.rb', '-c', 'configuration.yaml', 'register_map_0.xlsx', 'register_map_1.xlsx'
        ]
        options.parse(original_args)
        expect(options.register_map_files).to match(['register_map_0.xlsx', 'register_map_1.xlsx'])
      end
    end

    describe "setupオプション" do
      let(:setup_file) { '/foo/bar.rb' }

      context "--setupが引数で与えられた場合" do
        it "オプションで指定されたファイルのパスを返す" do
          options.parse(['--setup', setup_file])
          expect(options[:setup]).to eq setup_file
        end
      end

      context "--setupが未指定で" do
        context "環境変数RGGEN_DEFAULT_SETUP_FILEが定義されている場合" do
          before do
            allow(ENV).to receive(:[]).with('RGGEN_DEFAULT_SETUP_FILE').and_return(setup_file)
          end

          it "当該環境変数で指定されたファイルのパスを返す" do
            options.parse([])
            expect(options[:setup]).to eq setup_file
          end
        end

        context "rggen/default_setup_fileがrequireできる場合" do
          before do
            file = setup_file
            allow_any_instance_of(Options::Option).to receive(:require).with('rggen/default_setup_file') do
              ::RgGen.module_eval { const_set(:DEFAULT_SETUP_FILE, file) }
            end
          end

          after do
            ::RgGen.module_eval { remove_const(:DEFAULT_SETUP_FILE) }
          end

          it "当該ファイルで定義されるRGGEN::DEFAULT_SETUP_FILEで指定されれたファイルのパスを返す" do
            options.parse([])
            expect(options[:setup]).to eq setup_file
          end
        end

        context "上記以外の場合" do
          it "nilを返す" do
            options.parse([])
            expect(options[:setup]).to be nil
          end
        end
      end
    end

    describe "configurationオプション" do
      let(:configuration_files) do
        ['/foo/bar.yaml', '/foo/bar.json'].shuffle
      end

      context "-c/--configurationが引数で与えられた場合" do
        it "オプションで指定されたファイルのパスを返す" do
          options.parse(['-c', configuration_files[0]])
          expect(options[:configuration]).to eq configuration_files[0]

          options.parse(['--configuration', configuration_files[1]])
          expect(options[:configuration]).to eq configuration_files[1]
        end
      end

      context "-c/--configurationが未指定で" do
        context "環境変数RGGEN_DEFAULT_CONFIGURATION_FILEが定義されている場合" do
          let(:configuration_file) { configuration_files.sample }

          before do
            allow(ENV).to receive(:[]).with('RGGEN_DEFAULT_CONFIGURATION_FILE').and_return(configuration_file)
          end

          it "当該環境変数で指定されたファイルのパスを返す" do
            options.parse([])
            expect(options[:configuration]).to eq configuration_file
          end
        end

        context "環境変数RGGEN_DEFAULT_CONFIGURATION_FILEが未指定の場合" do
          it "nilを返す" do
            options.parse([])
            expect(options[:configuration]).to be nil
          end
        end
      end
    end

    describe "outputオプション" do
      context "-o/--outputが引数で指定された場合" do
        let(:output_directories) do
          ['foo', '/bar/baz'].shuffle
        end

        it "指定された出力ディレクトリを返す" do
          options.parse(['-o', output_directories[0]])
          expect(options[:output]).to eq output_directories[0]

          options.parse(['--output', output_directories[1]])
          expect(options[:output]).to eq output_directories[1]
        end
      end

      context "-o/--outputが未指定の場合" do
        it "'.'を返す" do
          options.parse([])
          expect(options[:output]).to eq "."
        end
      end
    end

    describe "load-onlyオプション" do
      context "--load-onlyが引数で指定された場合" do
        it "trueを返す" do
          options.parse(['--load-only'])
          expect(options[:load_only]).to be true
        end
      end

      context "--load-onlyが未指定の場合" do
        it "falseを返す" do
          options.parse([])
          expect(options[:load_only]).to be false
        end
      end
    end

    describe "exceptionsオプション" do
      context "--exceptが引数で指定された場合" do
        let(:exceptions) { ['foo', 'bar', 'baz'] }

        it "指定された除外生成物を配列で返す" do
          options.parse(['--except', exceptions[0], '--except', "#{exceptions[1]},#{exceptions[2]}"])
          expect(options[:exceptions]).to match(exceptions.map(&:to_sym))
        end
      end

      context "--exceptが未指定の場合" do
        it "空の配列を返す" do
          options.parse([])
          expect(options[:exceptions]).to be_instance_of(Array).and be_empty
        end
      end
    end
  end
end

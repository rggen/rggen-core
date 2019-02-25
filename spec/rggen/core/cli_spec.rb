require 'spec_helper'

module RgGen::Core
  describe CLI do
    let!(:cli) { CLI.new }

    let(:builder) { ::RgGen.builder }

    let(:setup) do
      proc do
        [:foo, :bar].each do |component|
          RgGen.output_component_registry(component) do
            register_component :register_map do
              component RgGen::Core::OutputBase::Component
              component_factory RgGen::Core::OutputBase::ComponentFactory
            end
            register_component [:register_block, :register, :bit_field] do
              component RgGen::Core::OutputBase::Component
              component_factory RgGen::Core::OutputBase::ComponentFactory
              base_feature RgGen::Core::OutputBase::Feature
              feature_factory RgGen::Core::OutputBase::FeatureFactory
            end
          end
        end

        RgGen.build do |builder|
          builder.define_simple_feature(:global, :prefix) do
            configuration do
              property :prefix, default: 'fizz'
              build { |v| @prefix = v }
            end
          end
          builder.enable(:global, :prefix)
        end

        [:register_block, :register, :bit_field].each do |category|
          RgGen.define_simple_feature(category, :name) do
            register_map do
              property :name
              build { |v| @name = v }
            end
          end
          RgGen.enable(category, :name)
        end

        RgGen.define_simple_feature(:register_block, :sample_writer) do
          foo do
            write_file 'foo_<%= register_block.name %>.txt' do |code|
              code << [configuration.prefix, 'foo', register_block.name].join('_') << "\n"
              code << [configuration.prefix, 'foo', register_map.registers.first.name].join('_') << "\n"
              code << [configuration.prefix, 'foo', register_map.bit_fields.first.name].join('_') << "\n"
            end

            def create_blank_file(_)
              +''
            end
          end
        end

        RgGen.setup do |builder|
          builder.define_simple_feature(:register_block, :sample_writer) do
            bar do
              write_file 'bar_<%= register_block.name %>.txt' do |code|
                code << [configuration.prefix, 'bar', register_block.name].join('_') << "\n"
                code << [configuration.prefix, 'bar', register_map.registers.first.name].join('_') << "\n"
                code << [configuration.prefix, 'bar', register_map.bit_fields.first.name].join('_') << "\n"
              end

              def create_blank_file(_)
                +''
              end
            end
          end
        end

        RgGen.enable(:register_block, :sample_writer)
      end
    end

    let(:setup_file) { 'setup.rb' }

    let(:configuration) { 'prefix "foo"' }

    let(:configuration_file) { 'configuration.rb' }

    let(:register_map_0) do
      <<~REGISTER_MAP
        register_block {
          name 'register_block_0'
          register {
            name 'register_0_0'
            bit_field {
              name 'bit_field_0_0_0'
            }
          }
        }
      REGISTER_MAP
    end

    let(:register_map_1) do
      <<~REGISTER_MAP
        register_block {
          name 'register_block_1'
          register {
            name 'register_1_0'
            bit_field {
              name 'bit_field_1_0_0'
            }
          }
        }
      REGISTER_MAP
    end

    let(:register_map_files) do
      ['register_map_0.rb', 'register_map_1.rb']
    end

    before do
      allow_any_instance_of(Options::Option).to receive(:require).with('lib/rggen/default_setup_file').and_raise(::LoadError)
      allow(ENV).to receive(:key?).with('RGGEN_DEFAULT_SETUP_FILE').and_return(false)
      allow(ENV).to receive(:key?).with('RGGEN_DEFAULT_CONFIGURATION_FILE').and_return(false)
    end

    before do
      allow(File).to receive(:readable?).with(setup_file).and_return(true)
      allow(cli).to receive(:load).with(setup_file, &setup)
    end

    before do
      allow(File).to receive(:readable?).with(register_map_files[0]).and_return(true)
      allow(File).to receive(:binread).with(register_map_files[0]).and_return(register_map_0)
      allow(File).to receive(:readable?).with(register_map_files[1]).and_return(true)
      allow(File).to receive(:binread).with(register_map_files[1]).and_return(register_map_1)
    end

    before do
      allow(File).to receive(:binwrite)
    end

    describe "セットアップファイルの読み込み" do
      context "存在するセットアップファイルが指定された場合" do
        it "指定されたファイルを読み込んで、セットアップを実行する" do
          expect(builder).to receive(:output_component_registry).with(:foo).and_call_original
          expect(builder).to receive(:output_component_registry).with(:bar).and_call_original
          cli.run(['--setup', setup_file, *register_map_files])
        end
      end

      context "存在しないセットアップファイルが指定された場合" do
        let(:invalid_setup_file) { 'invalid_setup_file.rb' }

        before do
          allow(File).to receive(:readable?).with(invalid_setup_file).and_return(false)
        end

        it "LoadErrorを起こす" do
          expect {
            cli.run(['--setup', invalid_setup_file])
          }.to raise_error RgGen::Core::LoadError, "cannot load such file -- #{invalid_setup_file}"
        end
      end

      context "セットアップフィアルの指定がない場合" do
        it "LoadErrorを起こす" do
          expect {
            cli.run([])
          }.to raise_error RgGen::Core::LoadError, 'no setup file is given'
        end
      end
    end

    describe "コンフィグレーションの生成と読み込み" do
      let(:configurations) { [] }

      before do
        allow(Configuration::Component).to receive(:new).and_wrap_original do |m, *args, &b|
          configurations << m.call(*args, &b)
          configurations.last
        end
      end

      context "コンフィグレーションファイルが指定された場合" do
        before do
          allow(File).to receive(:readable?).with(configuration_file).and_return(true)
          allow(File).to receive(:binread).with(configuration_file).and_return(configuration)
        end

        it "コンフィグレーションの生成と、コンフィグレーションファイルの読み込みを行う" do
          cli.run(['--setup', setup_file, '-c', configuration_file, *register_map_files])
          expect(configurations.last.prefix).to eq 'foo'
        end
      end

      context "コンフィグレーションファイルの指定がない場合" do
        it "コンフィグレーションの生成のみ行う" do
          cli.run(['--setup', setup_file, *register_map_files])
          expect(configurations.last.prefix).to eq 'fizz'
        end
      end
    end

    describe "レジスタマップの読み込み" do
      let(:regiter_maps) { [] }

      before do
        allow(RegisterMap::Component).to receive(:new).and_wrap_original do |m, *args, &b|
          c = m.call(*args, &b)
          c.parent || (regiter_maps << c)
          c
        end
      end

      it "パース後の残引数をレジスタマップへのパスとして、レジスタマップの読み込みを行う" do
        cli.run(['--setup', setup_file, *register_map_files])
        expect(regiter_maps.last.register_blocks[0].name).to eq 'register_block_0'
        expect(regiter_maps.last.register_blocks[1].name).to eq 'register_block_1'
        expect(regiter_maps.last.registers[0].name).to eq 'register_0_0'
        expect(regiter_maps.last.registers[1].name).to eq 'register_1_0'
        expect(regiter_maps.last.bit_fields[0].name).to eq 'bit_field_0_0_0'
        expect(regiter_maps.last.bit_fields[1].name).to eq 'bit_field_1_0_0'
      end

      context "レジスタマップの指定がない場合" do
        it do
          expect {
            cli.run(['--setup', setup_file])
          }.to raise_error RgGen::Core::LoadError, 'no register map files are given'
        end
      end
    end

    describe "ファイルの書き出し" do
      let(:foo_file_contents) do
        [
          'fizz_foo_register_block_0',
          'fizz_foo_register_0_0',
          'fizz_foo_bit_field_0_0_0',
          ''
        ].join("\n")
      end

      let(:bar_file_contents) do
        [
          'fizz_bar_register_block_0',
          'fizz_bar_register_0_0',
          'fizz_bar_bit_field_0_0_0',
          ''
        ].join("\n")
      end

      context "出力ディレクトリの指定がない場合" do
        it "カレントディレクトリにファイルを書き出す" do
          expect(File).to receive(:binwrite).with(match_string('./foo_register_block_0.txt'), foo_file_contents)
          expect(File).to receive(:binwrite).with(match_string('./bar_register_block_0.txt'), bar_file_contents)
          cli.run(['--setup', setup_file, register_map_files[0]])
        end
      end

      context "出力ディレクトリの指定がある場合" do
        it "指定されたディレクトリにファイルを書き出す" do
          expect(File).to receive(:binwrite).with(match_string('out/foo_register_block_0.txt'), foo_file_contents)
          expect(File).to receive(:binwrite).with(match_string('out/bar_register_block_0.txt'), bar_file_contents)
          cli.run(['--setup', setup_file, '-o', 'out', register_map_files[0]])
        end
      end

      context "除外指定がある場合" do
        it "除外されたファイル形式は書き出さない" do
          expect(File).to receive(:binwrite).with(match_string('./foo_register_block_0.txt'), foo_file_contents)
          expect(File).not_to receive(:binwrite).with(match_string('./bar_register_block_0.txt'), any_args)
          cli.run(['--setup', setup_file, '--except', 'bar', register_map_files[0]])
        end
      end

      context "--load-onlyが指定された場合" do
        it "ファイルの書き出しは行わない" do
          expect(File).not_to receive(:binwrite)
          cli.run(['--setup', setup_file, '--load-only', register_map_files[0]])
        end
      end
    end
  end
end

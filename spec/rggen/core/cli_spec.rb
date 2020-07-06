# frozen_string_literal: true

RSpec.describe RgGen::Core::CLI do
  let(:cli) { described_class.new }

  let(:builder) { cli.builder }

  let(:setup) do
    proc do
      RgGen.define_simple_feature(:global, :prefix) do
        configuration do
          property :prefix, default: 'fizz'
          build { |v| @prefix = v }
        end
      end
      RgGen.enable(:global, :prefix)

      [:register_block, :register_file, :register, :bit_field].each do |layer|
        RgGen.define_simple_feature(layer, :name) do
          register_map do
            property :name
            build { |v| @name = v }
          end
        end
        RgGen.enable(layer, :name)
      end

      [:foo, :bar].each do |component_name|
        plugin_module = Module.new do
          singleton_exec do
            define_method(:version) do
              { foo: '0.0.1', bar: '0.0.2'}[component_name]
            end
            define_method(:default_setup) do |builder|
              builder.output_component_registry(component_name) do
                register_component :root do
                  component(
                    RgGen::Core::OutputBase::Component,
                    RgGen::Core::OutputBase::ComponentFactory
                  )
                end
                register_component [:register_block, :register_file, :register, :bit_field] do
                  component(
                    RgGen::Core::OutputBase::Component,
                    RgGen::Core::OutputBase::ComponentFactory
                  )
                  feature(
                    RgGen::Core::OutputBase::Feature,
                    RgGen::Core::OutputBase::FeatureFactory
                  )
                end
              end

              RgGen.define_simple_feature(:register_block, :sample_writer) do
                send(component_name) do
                  write_file "#{component_name}_<%= register_block.name %>.txt" do |code|
                    code << [configuration.prefix, "#{component_name}", register_block.name].join('_') << "\n"

                    register_file = register_block.files_and_registers.first
                    code << [configuration.prefix, "#{component_name}", register_file.name].join('_') << "\n"

                    register = register_file.files_and_registers.first
                    code << [configuration.prefix, "#{component_name}", register.name].join('_') << "\n"

                    bit_field = register.bit_fields.first
                    code << [configuration.prefix, "#{component_name}", bit_field.name].join('_') << "\n"
                  end

                  def create_blank_file(_)
                    +''
                  end
                end
              end
            end
          end
        end

        RgGen.setup(:"rggen-#{component_name}", plugin_module) do |builder|
          builder.enable(:register_block, :sample_writer)
        end
      end
    end
  end

  let(:setup_file) { 'setup.rb' }

  let(:configuration) { 'prefix "foo"' }

  let(:configuration_file) { 'configuration.rb' }

  let(:register_map_0) do
    <<~REGISTER_MAP
      register_block {
        name 'register_block_0'
        register_file {
          name 'register_file_0'
          register {
            name 'register_0'
            bit_field {
              name 'bit_field_0'
            }
          }
        }
      }
    REGISTER_MAP
  end

  let(:register_map_1) do
    <<~REGISTER_MAP
      register_block {
        name 'register_block_1'
        register_file {
          name 'register_file_1'
          register {
            name 'register_1'
            bit_field {
              name 'bit_field_1'
            }
          }
        }
      }
    REGISTER_MAP
  end

  let(:register_map_files) do
    ['register_map_0.rb', 'register_map_1.rb']
  end

  before do
    allow(cli.options).to receive(:require).with('rggen/default_setup_file').and_raise(::LoadError)
    allow(ENV).to receive(:[]).with('RGGEN_DEFAULT_SETUP_FILE').and_return(nil)
    allow(ENV).to receive(:[]).with('RGGEN_DEFAULT_CONFIGURATION_FILE').and_return(nil)
  end

  before do
    allow(File).to receive(:readable?).with(setup_file).and_return(true)
    allow(builder).to receive(:load).with(setup_file, &setup)
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

  describe 'Builderの初期化' do
    before { RgGen.builder(nil) }

    context 'Builderが未指定の場合' do
      it 'Builderを生成し、CLI#builderに設定する' do
        builder = nil
        expect(RgGen::Core::Builder).to receive(:create).and_wrap_original do |m|
          m.call.tap { |b| builder = b }
        end

        cli = described_class.new
        expect(cli.builder).to be builder
      end
    end

    context 'Builderが指定された場合' do
      it '指定されたBuilderをRgGen.builderに設定する' do
        builder = RgGen::Core::Builder.create
        expect(RgGen::Core::Builder).not_to receive(:create)

        cli = described_class.new(builder)
        expect(cli.builder).to be builder
      end
    end
  end

  describe '--help/-hオプション' do
    let(:help_message) do
      <<~'HELP'
        Usage: rggen [options] register_map_files
                --setup FILE                 Specify a Ruby file to set up RgGen tool
            -c, --configuration FILE         Specify a configuration file
            -o, --output DIRECTORY           Specify the directory where generated file(s) will be written
                --load-only                  Load setup, configuration and register map files only; write no files
                --enable WRITER1[,WRITER2,...]
                                             Enable only the given writer(s) to write files
                --print-backtrace            Print backtrace when an error occurs
            -v, --version                    Display version
                --verbose-version            Load a setup Ruby file and display verbose version
            -h, --help                       Display this message
      HELP
    end

    it 'ヘルプを出力する' do
      expect {
        cli.run(['--help'])
      }.to output(help_message).to_stdout

      expect {
        cli.run(['-h'])
      }.to output(help_message).to_stdout
    end
  end

  describe '--version/-vオプション' do
    let(:version) do
      "RgGen #{RgGen::Core::MAJOR}.#{RgGen::Core::MINOR}\n"
    end

    it 'バージョン情報を出力する' do
      expect {
        cli.run(['--version'])
      }.to output(version).to_stdout

      expect {
        cli.run(['-v'])
      }.to output(version).to_stdout
    end
  end

  describe '--verbose-version/-Vオプション' do
    context 'セットアップファイルが読める場合' do
      let(:version) do
        <<~VERSION
          RgGen #{RgGen::Core::MAJOR}.#{RgGen::Core::MINOR}
            - rggen-core #{RgGen::Core::VERSION}
            - rggen-foo 0.0.1
            - rggen-bar 0.0.2
        VERSION
      end

      it 'セットアップファイルを読んだ上で、詳細なバージョン情報を出力する' do
        expect(builder).to receive(:load_setup_file).with(setup_file, false).and_call_original
        expect {
          cli.run(['--verbose-version', '--setup', setup_file])
        }.to output(version).to_stdout
      end
    end

    context 'セットアップファイルの指定がない場合' do
      let(:version) do
        <<~VERSION
          RgGen #{RgGen::Core::MAJOR}.#{RgGen::Core::MINOR}
            - rggen-core #{RgGen::Core::VERSION}
        VERSION
      end

      it 'コアライブラリのバージョンのみを表示する' do
        expect {
          cli.run(['--verbose-version'])
        }.to output(version).to_stdout
      end
    end

    context 'セットアップファイルが読めない場合' do
      let(:invalid_setup_file) { 'invalid_setup_file.rb' }

      before do
        allow(File).to receive(:readable?).with(invalid_setup_file).and_return(false)
      end

      it 'Loaderエラーを起こす' do
        expect {
          cli.run(['--verbose-version', '--setup', invalid_setup_file])
        }.to raise_error RgGen::Core::LoadError
      end
    end
  end

  describe 'セットアップファイルの読み込み' do
    context '存在するセットアップファイルが指定された場合' do
      it '指定されたファイルを読み込んで、セットアップを実行する' do
        expect(builder).to receive(:load_setup_file).with(setup_file).and_call_original
        cli.run(['--setup', setup_file, *register_map_files])
      end
    end
  end

  describe 'コンフィグレーションの生成と読み込み' do
    let(:configurations) { [] }

    before do
      allow(RgGen::Core::Configuration::Component).to receive(:new).and_wrap_original do |m, *args, &b|
        configurations << m.call(*args, &b)
        configurations.last
      end
    end

    context 'コンフィグレーションファイルが指定された場合' do
      before do
        allow(File).to receive(:readable?).with(configuration_file).and_return(true)
        allow(File).to receive(:binread).with(configuration_file).and_return(configuration)
      end

      it 'コンフィグレーションの生成と、コンフィグレーションファイルの読み込みを行う' do
        cli.run(['--setup', setup_file, '-c', configuration_file, *register_map_files])
        expect(configurations.last.prefix).to eq 'foo'
      end
    end

    context 'コンフィグレーションファイルの指定がない場合' do
      it 'コンフィグレーションの生成のみ行う' do
        cli.run(['--setup', setup_file, *register_map_files])
        expect(configurations.last.prefix).to eq 'fizz'
      end
    end
  end

  describe 'レジスタマップの読み込み' do
    let(:register_maps) { [] }

    before do
      allow(RgGen::Core::RegisterMap::Component).to receive(:new).and_wrap_original do |m, *args, &b|
        c = m.call(*args, &b)
        c.parent || (register_maps << c)
        c
      end
    end

    it 'パース後の残引数をレジスタマップへのパスとして、レジスタマップの読み込みを行う' do
      cli.run(['--setup', setup_file, *register_map_files])

      register_blocks = register_maps.last.register_blocks
      expect(register_blocks[0].name).to eq 'register_block_0'
      expect(register_blocks[1].name).to eq 'register_block_1'

      register_files = register_blocks.flat_map(&:files_and_registers)
      expect(register_files[0].name).to eq 'register_file_0'
      expect(register_files[1].name).to eq 'register_file_1'

      registers = register_files.flat_map(&:files_and_registers)
      expect(registers[0].name).to eq 'register_0'
      expect(registers[1].name).to eq 'register_1'

      bit_fields = registers.flat_map(&:bit_fields)
      expect(bit_fields[0].name).to eq 'bit_field_0'
      expect(bit_fields[1].name).to eq 'bit_field_1'
    end

    context 'レジスタマップの指定がない場合' do
      it do
        expect {
          cli.run(['--setup', setup_file])
        }.to raise_rggen_error RgGen::Core::LoadError, 'no register map files are given'
      end
    end
  end

  describe 'ファイルの書き出し' do
    let(:foo_file_content) do
      [
        'fizz_foo_register_block_0',
        'fizz_foo_register_file_0',
        'fizz_foo_register_0',
        'fizz_foo_bit_field_0',
        ''
      ].join("\n")
    end

    let(:bar_file_content) do
      [
        'fizz_bar_register_block_0',
        'fizz_bar_register_file_0',
        'fizz_bar_register_0',
        'fizz_bar_bit_field_0',
        ''
      ].join("\n")
    end

    context '出力ディレクトリの指定がない場合' do
      it 'カレントディレクトリにファイルを書き出す' do
        expect(File).to receive(:binwrite).with(match_string('./foo_register_block_0.txt'), foo_file_content)
        expect(File).to receive(:binwrite).with(match_string('./bar_register_block_0.txt'), bar_file_content)
        cli.run(['--setup', setup_file, register_map_files[0]])
      end
    end

    context '出力ディレクトリの指定がある場合' do
      it '指定されたディレクトリにファイルを書き出す' do
        expect(File).to receive(:binwrite).with(match_string('out/foo_register_block_0.txt'), foo_file_content)
        expect(File).to receive(:binwrite).with(match_string('out/bar_register_block_0.txt'), bar_file_content)
        cli.run(['--setup', setup_file, '-o', 'out', register_map_files[0]])
      end
    end

    context '対象指定がある場合' do
      it '指定外のファイル形式は書き出さない' do
        expect(File).to receive(:binwrite).with(match_string('./foo_register_block_0.txt'), foo_file_content)
        expect(File).not_to receive(:binwrite).with(match_string('./bar_register_block_0.txt'), any_args)
        cli.run(['--setup', setup_file, '--enable', 'foo', register_map_files[0]])
      end
    end

    context '--load-onlyが指定された場合' do
      it 'ファイルの書き出しは行わない' do
        expect(File).not_to receive(:binwrite)
        cli.run(['--setup', setup_file, '--load-only', register_map_files[0]])
      end
    end
  end
end

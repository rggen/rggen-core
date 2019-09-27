# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::OutputBase
  describe Feature do
    let(:configuration) do
      RgGen::Core::Configuration::Component.new('configuration', nil)
    end

    let(:register_map) do
      RgGen::Core::RegisterMap::Component.new('register_map', nil, configuration)
    end

    let(:component) do
      RgGen::Core::OutputBase::Component.new('component', nil, configuration, register_map)
    end

    def define_feature(super_class = nil, &block)
      Class.new(super_class || Feature, &block)
    end

    def define_and_create_feature(super_class = nil, &block)
      define_feature(super_class, &block).new(component, :feature)
    end

    describe '#pre_build' do
      it '.pre_buildで登録されたブロックを実行し、フィーチャーの事前組み立てを行う' do
        feature = define_and_create_feature do
          pre_build { @foo = component.foo }
          pre_build { @bar = component.bar }
        end

        allow(component).to receive(:foo).and_return('foo')
        allow(component).to receive(:bar).and_return('bar')
        feature.pre_build

        expect(feature.instance_variable_get(:@foo)).to be component.foo
        expect(feature.instance_variable_get(:@bar)).to be component.bar
      end

      context '継承された場合' do
        specify '親クラスの組み立てブロックは継承される' do
          parent_feature = define_feature do
            pre_build { @foo = component.foo }
          end
          feature = define_and_create_feature(parent_feature) do
            pre_build { @bar = component.bar }
          end

          allow(component).to receive(:foo).and_return('foo')
          allow(component).to receive(:bar).and_return('bar')
          feature.pre_build

          expect(feature.instance_variable_get(:@foo)).to be component.foo
          expect(feature.instance_variable_get(:@bar)).to be component.bar
        end
      end

      context '組み立てブロックが未登録の場合' do
        it 'エラーなく実行できる' do
          feature = define_and_create_feature
          expect {
            feature.pre_build
          }.to_not raise_error
        end
      end
    end

    describe '#build' do
      it '.buildで登録されたブロックを実行し、フィーチャーの組み立てを行う' do
        feature = define_and_create_feature do
          build { @foo = component.foo }
          build { @bar = component.bar }
        end

        allow(component).to receive(:foo).and_return('foo')
        allow(component).to receive(:bar).and_return('bar')
        feature.build

        expect(feature.instance_variable_get(:@foo)).to be component.foo
        expect(feature.instance_variable_get(:@bar)).to be component.bar
      end

      context '継承された場合' do
        specify '親クラスの組み立てブロックは継承される' do
          parent_feature = define_feature do
            build { @foo = component.foo }
          end
          feature = define_and_create_feature(parent_feature) do
            build { @bar = component.bar }
          end

          allow(component).to receive(:foo).and_return('foo')
          allow(component).to receive(:bar).and_return('bar')
          feature.build

          expect(feature.instance_variable_get(:@foo)).to be component.foo
          expect(feature.instance_variable_get(:@bar)).to be component.bar
        end
      end

      context '組み立てブロックが未登録の場合' do
        it 'エラーなく実行できる' do
          feature = define_and_create_feature
          expect {
            feature.build
          }.to_not raise_error
        end
      end
    end

    shared_context 'template engine' do
      let(:template_engine) do
        Class.new(TemplateEngine) do
          def file_extension
            :erb
          end
          def parse_template(path)
            Erubi::Engine.new(File.binread(path))
          end
          def render(context, template)
            context.instance_eval(template.src)
          end
        end
      end

      let(:default_template_path) { File.ext(__FILE__, 'erb') }

      let(:template) { '<%= object_id %>' }
    end

    shared_examples_for 'code_generator' do |phase|
      it ".#{phase}で登録されたブロックを実行し、コードの生成を行う" do
        feature = define_and_create_feature do
          send(phase, :foo) { |c| c << 'foo' }
          send(phase, :bar) { 'bar' }
        end

        expect(code).to receive(:<<).with('foo')
        feature.generate_code(phase, :foo, nil)

        expect(code).to receive(:<<).with('bar')
        feature.generate_code(phase, :bar, code)
      end

      specify '同名のコード生成ブロックを複数個登録できる' do
        feature = define_and_create_feature do
          send(phase, :foo) { 'foo_0' }
          send(phase, :foo) { 'foo_1' }
        end

        expect(code).to receive(:<<).with('foo_0')
        expect(code).to receive(:<<).with('foo_1')
        feature.generate_code(phase, :foo, code)
      end

      context '未登録のコードの種類が指定された場合' do
        it 'コードの生成は行わない' do
          feature = define_and_create_feature do
            send(phase, :foo) { 'foo' }
          end

          expect(code).not_to receive(:<<)
          feature.generate_code(phase, :bar, nil)
          feature.generate_code(phase, :bar, code)
        end
      end

      it '生成したコードオブジェクト、または、与えたコードオブジェクトを返す' do
        allow(code).to receive(:<<)

        feature = define_and_create_feature do
          send(phase, :foo) { 'foo' }
        end

        expect(feature.generate_code(phase, :foo, nil )).to be code
        expect(feature.generate_code(phase, :foo, code)).to be code
        expect(feature.generate_code(phase, :bar, nil )).to be nil
        expect(feature.generate_code(phase, :bar, code)).to be code
      end

      describe 'from_template option' do
        include_context 'template engine'

        it 'テンプレートを処理して、コードを生成する' do
          engine = template_engine
          feature = define_and_create_feature do
            template_engine engine
            send(phase, :foo, from_template: 'foo.erb')
            send(phase, :bar, from_template: true)
          end

          allow(File).to receive(:binread).with('foo.erb').and_return(template)
          expect(code).to receive(:<<).with("#{feature.object_id}")
          feature.generate_code(phase, :foo, code)

          allow(File).to receive(:binread).with(default_template_path).and_return(template)
          expect(code).to receive(:<<).with("#{feature.object_id}")
          feature.generate_code(phase, :bar, code)
        end

        context 'from_templateにfalseが指定された場合' do
          it 'テンプレートからコードの生成を行わない' do
            feature = define_and_create_feature do
              send(phase, :foo, from_template: false)
            end

            expect(File).not_to receive(:binread)
            expect(code).not_to receive(:<<)
            feature.generate_code(phase, :foo, code)
          end
        end
      end

      context '継承された場合' do
        specify 'コード生成ブロックは継承される' do
          parent_feature = define_feature do
            send(phase, :foo) { 'foo' }
            send(phase, :bar) { 'bar' }
          end
          feature = define_and_create_feature(parent_feature)

          expect(code).to receive(:<<). with('foo')
          feature.generate_code(phase, :foo, code)

          expect(code).to receive(:<<). with('bar')
          feature.generate_code(phase, :bar, code)
        end

        specify '継承先での変更は、親クラスに影響しない' do
          parent_feature = define_and_create_feature do
            send(phase, :foo) { 'foo_0' }
          end
          feature = define_and_create_feature(parent_feature.class) do
            send(phase, :foo) { 'foo_1' }
          end

          expect(code).to receive(:<<).with('foo_0')
          expect(code).to receive(:<<).with('foo_1')
          feature.generate_code(phase, :foo, code)


          expect(code).to receive(:<<).with('foo_0')
          expect(code).not_to receive(:<<).with('foo_1')
          parent_feature.generate_code(phase, :foo, code)
        end
      end
    end

    describe '#generate_code' do
      let(:code) { double('code') }

      before do
        allow_any_instance_of(Feature).to receive(:create_blank_code).and_return(code)
      end

      context '生成フェーズが:pre_codeの場合' do
        it_behaves_like 'code_generator', :pre_code
      end

      context '生成フェーズが:main_codeの場合' do
        it_behaves_like 'code_generator', :main_code
      end

      context '生成フェーズが:post_codeの場合' do
        it_behaves_like 'code_generator', :post_code
      end
    end

    describe '#write_file' do
      let(:feature_base) do
        Class.new(Feature) do
          def create_blank_file(_path); ''.dup; end
        end
      end

      it '.write_fileで与えられたブロックの実行し、結果をファイルに書き出す' do
        feature = define_and_create_feature(feature_base) do
          write_file 'foo.txt' do |f|
            f << file_content
          end
          def file_content; "#{object_id} foo"; end
        end

        expect(File).to receive(:binwrite).with(any_args, feature.file_content)
        feature.write_file
      end

      it '.write_fileで指定したパターンのファイル名でファイルを書き出す' do
        feature = define_and_create_feature(feature_base) do
          write_file '<%= file_name %>' do
          end
          def file_name; "#{object_id}_foo.txt"; end
        end

        expect(File).to receive(:binwrite).with(match_string(feature.file_name), any_args)
        feature.write_file
      end

      context '出力ディレクトリが指定された場合' do
        it '指定されたディレクトリにファイルを書き出す' do
          feature = define_and_create_feature(feature_base) do
            write_file 'baz.txt' do
            end
          end

          expect(File).to receive(:binwrite).with(match_string('bar/baz.txt'), any_args)
          feature.write_file('bar')

          expect(File).to receive(:binwrite).with(match_string('foo/bar/baz.txt'), any_args)
          feature.write_file('foo/bar')

          expect(File).to receive(:binwrite).with(match_string('foo/bar/baz.txt'), any_args)
          feature.write_file(['foo', 'bar'])
        end

        context '継承された場合' do
          specify 'ファイル名のパターンと内容を生成するブロックは継承される' do
            parent_feature = define_feature(feature_base) do
              write_file '<%= file_name %>' do |f|
                f << file_content
              end
            end
            feature = define_and_create_feature(parent_feature) do
              def file_name; "#{object_id}_foo.txt"; end
              def file_content; "#{object_id} foo !"; end
            end

            expect(File).to receive(:binwrite).with(match_string(feature.file_name), feature.file_content)
            feature.write_file
          end
        end

        context 'ファイル名のパターンと内容を生成するブロックが未登録の場合' do
          it 'エラーなく実行できる' do
            feature = define_and_create_feature do
            end

            expect(File).not_to receive(:binwrite)
            expect {
              feature.write_file
            }.to_not raise_error
          end
        end
      end
    end

    describe '#exported_methods' do
      it '.export/#exportで指定されたメソッド一覧を返す' do
        feature = define_and_create_feature do
          export :foo
          export :bar, :baz
          export :foo
          build do
            export :fizz
            export :buzz, :fizzbuzz
            export :fizz, :foo
          end
        end
        feature.build

        expect(feature.exported_methods(:class)).to match [:foo, :bar, :baz]
        expect(feature.exported_methods(:object)).to match [:fizz, :buzz, :fizzbuzz]
      end

      context '継承された場合' do
        specify '.exportで指定されたメソッド一覧は継承される' do
          foo_feature = define_and_create_feature do
            export :foo
          end
          bar_feature = define_and_create_feature(foo_feature.class) do
            export :bar
          end
          baz_feature = define_and_create_feature(bar_feature.class) do
            export :baz
          end

          expect(foo_feature.exported_methods(:class)).to match [:foo]
          expect(bar_feature.exported_methods(:class)).to match [:foo, :bar]
          expect(baz_feature.exported_methods(:class)).to match [:foo, :bar, :baz]
        end
      end
    end

    describe '#process_template' do
      include_context 'template engine'

      let(:code) { double('code') }

      it 'テンプレートエンジンでテンプレートを処理し、コードを生成する' do
        engine = template_engine
        foo_feature = define_and_create_feature do
          template_engine engine
          main_code(:foo) { process_template }
        end
        bar_feature = define_and_create_feature(foo_feature.class) do
          main_code(:bar) { process_template('bar.erb') }
        end

        allow(File).to receive(:binread).with(default_template_path).and_return(template)
        expect(code).to receive(:<<).with("#{foo_feature.object_id}")
        foo_feature.generate_code(:main_code, :foo, code)

        allow(File).to receive(:binread).with('bar.erb').and_return(template)
        expect(code).to receive(:<<).with("#{bar_feature.object_id}")
        bar_feature.generate_code(:main_code, :bar, code)
      end
    end
  end
end

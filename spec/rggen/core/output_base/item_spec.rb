require 'spec_helper'

module RgGen::Core::OutputBase
  describe Item do
    let(:configuration) do
      RgGen::Core::Configuration::Component.new(nil)
    end

    let(:register_map) do
      RgGen::Core::RegisterMap::Component.new(nil, configuration)
    end

    let(:component) do
      RgGen::Core::OutputBase::Component.new(nil, configuration, register_map)
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

    def define_item(super_class = nil, &block)
      Class.new(super_class || Item, &block)
    end

    def define_and_create_item(super_class = nil, &block)
      define_item(super_class, &block).new(component, :item)
    end

    describe "#build" do
      it ".buildで登録されたブロックを実行し、アイテムの組み立てを行う" do
        item = define_and_create_item do
          build { @foo = component.foo }
          build { @bar = component.bar }
        end

        allow(component).to receive(:foo).and_return('foo')
        allow(component).to receive(:bar).and_return('bar')
        item.build

        expect(item.instance_variable_get(:@foo)).to be component.foo
        expect(item.instance_variable_get(:@bar)).to be component.bar
      end

      context "継承された場合" do
        specify "親クラスの組み立てブロックは継承される" do
          parent_item = define_item do
            build { @foo = component.foo }
          end
          item = define_and_create_item(parent_item) do
            build { @bar = component.bar }
          end

          allow(component).to receive(:foo).and_return('foo')
          allow(component).to receive(:bar).and_return('bar')
          item.build

          expect(item.instance_variable_get(:@foo)).to be component.foo
          expect(item.instance_variable_get(:@bar)).to be component.bar
        end
      end

      context "組み立てブロックが未登録の場合" do
        it "エラーなく実行できる" do
          item = define_and_create_item
          expect {
            item.build
          }.to_not raise_error
        end
      end
    end

    shared_examples_for "code_generator" do |generator_method, api_method|
      let(:code) { double('code') }

      before do
        allow_any_instance_of(Item).to receive(:create_blank_code).and_return(code)
      end

      it ".#{api_method}で登録されたブロックを実行し、コードの生成を行う" do
        item  = define_and_create_item do
          send(api_method, :foo) { |c| c << 'foo' }
          send(api_method, :bar) { 'bar' }
        end

        expect(code).to receive(:<<).with('foo')
        item.send(generator_method, :foo, nil)

        expect(code).to receive(:<<).with('bar')
        item.send(generator_method, :bar, code)
      end

      specify "最後に登録されたコード生成ブロックが優先される" do
        item = define_and_create_item do
          send(api_method, :foo) { 'foo_0' }
          send(api_method, :foo) { 'foo_1' }
        end

        expect(code).to receive(:<<).with('foo_1')
        item.send(generator_method, :foo, code)
      end

      context "未登録のコードの種類が指定された場合" do
        it "コードの生成は行わない" do
          item = define_and_create_item do
            send(api_method, :foo) { 'foo' }
          end

          expect(code).not_to receive(:<<)
          item.send(generator_method, :bar, nil)
          item.send(generator_method, :bar, code)
        end
      end

      it "生成したコードオブジェクト、または、与えたコードオブジェクトを返す" do
        allow(code).to receive(:<<)

        item = define_and_create_item do
          send(api_method, :foo) { 'foo' }
        end

        expect(item.send(generator_method, :foo, nil )).to be code
        expect(item.send(generator_method, :foo, code)).to be code
        expect(item.send(generator_method, :bar, nil )).to be nil
        expect(item.send(generator_method, :bar, code)).to be code
      end

      describe "from_template/template_path option" do
        include_context 'template engine'

        it "テンプレートを処理して、コードを生成する" do
          engine = template_engine
          item = define_and_create_item do
            template_engine engine
            send(api_method, :foo, from_template: true, template_path: 'foo.erb')
            send(api_method, :bar,                      template_path: 'bar.erb')
            send(api_method, :baz, from_template: true)
          end

          allow(File).to receive(:binread).with('foo.erb').and_return(template)
          expect(code).to receive(:<<).with("#{item.object_id}")
          item.send(generator_method, :foo, code)

          allow(File).to receive(:binread).with('bar.erb').and_return(template)
          expect(code).to receive(:<<).with("#{item.object_id}")
          item.send(generator_method, :bar, code)

          allow(File).to receive(:binread).with(default_template_path).and_return(template)
          expect(code).to receive(:<<).with("#{item.object_id}")
          item.send(generator_method, :baz, code)
        end

        context "from_templateにfalseが指定された場合" do
          it "template_pathが指定されていても、テンプレートからコードの生成を行わない" do
            item = define_and_create_item do
              send(api_method, :foo, from_template: false, template_path: 'foo.erb')
            end

            expect(File).not_to receive(:binread).with('foo.erb')
            expect(code).not_to receive(:<<)
            item.send(generator_method, :foo, code)
          end
        end
      end

      context "継承された場合" do
        specify "コード生成ブロックは継承される" do
          parent_item = define_item do
            send(api_method, :foo) { 'foo' }
            send(api_method, :bar) { 'bar' }
          end
          item = define_and_create_item(parent_item)

          expect(code).to receive(:<<). with('foo')
          item.send(generator_method, :foo, code)

          expect(code).to receive(:<<). with('bar')
          item.send(generator_method, :bar, code)
        end

        specify "コード生成ブロックは上書き可能である"  do
          parent_item = define_item do
            send(api_method, :foo) { 'foo_0' }
          end
          item = define_and_create_item(parent_item) do
            send(api_method, :foo) { 'foo_1' }
          end

          expect(code).to receive(:<<).with('foo_1')
          item.send(generator_method, :foo, code)
        end

        specify "継承先での変更は、親クラスに影響しない" do
          item = define_and_create_item do
            send(api_method, :foo) { 'foo_0' }
          end
          define_item(item.class) do
            send(api_method, :foo) { 'foo_1' }
          end

          expect(code).to receive(:<<).with('foo_0')
          item.send(generator_method, :foo, code)
        end
      end
    end

    describe "#generate_pre_code" do
      it_behaves_like "code_generator", :generate_pre_code, :pre_code
    end

    describe "#generate_main_code" do
      it_behaves_like "code_generator", :generate_main_code, :main_code
    end

    describe "#generate_post_code" do
      it_behaves_like "code_generator", :generate_post_code, :post_code
    end

    describe "#write_file" do
      before do
        allow_any_instance_of(Item).to receive(:create_blank_file).and_return(''.dup)
      end

      it ".write_fileで与えられたブロックの実行し、結果をファイルに書き出す" do
        item = define_and_create_item do
          write_file 'foo.txt' do |f|
            f << file_content
          end
          def file_content; "#{object_id} foo"; end
        end

        expect(File).to receive(:binwrite).with(any_args, item.file_content)
        item.write_file
      end

      it ".write_fileで指定したパターンのファイル名でファイルを書き出す" do
        item = define_and_create_item do
          write_file '<%= file_name %>' do
          end
          def file_name; "#{object_id}_foo.txt"; end
        end

        expect(File).to receive(:binwrite).with(match_string(item.file_name), any_args)
        item.write_file
      end

      context "出力ディレクトリが指定された場合" do
        it "指定されたディレクトリにファイルを書き出す" do
          item = define_and_create_item do
            write_file 'baz.txt' do
            end
          end

          expect(File).to receive(:binwrite).with(match_string('bar/baz.txt'), any_args)
          item.write_file('bar')

          expect(File).to receive(:binwrite).with(match_string('foo/bar/baz.txt'), any_args)
          item.write_file('foo/bar')

          expect(File).to receive(:binwrite).with(match_string('foo/bar/baz.txt'), any_args)
          item.write_file(['foo', 'bar'])
        end

        context "継承された場合" do
          specify "ファイル名のパターンと内容を生成するブロックは継承される" do
            parent_item = define_item do
              write_file '<%= file_name %>' do |f|
                f << file_content
              end
            end
            item = define_and_create_item(parent_item) do
              def file_name; "#{object_id}_foo.txt"; end
              def file_content; "#{object_id} foo !"; end
            end

            expect(File).to receive(:binwrite).with(match_string(item.file_name), item.file_content)
            item.write_file
          end
        end

        context "ファイル名のパターンと内容を生成するブロックが未登録の場合" do
          it "エラーなく実行できる" do
            item = define_and_create_item do
            end

            expect(File).not_to receive(:binwrite)
            expect {
              item.write_file
            }.to_not raise_error
          end
        end
      end
    end

    describe "#exported_methods" do
      it ".exportで指定されたメソッド一覧を返す" do
        item = define_and_create_item do
          export :foo
          export :bar, :baz
          export :foo
        end

        expect(item.exported_methods).to match [:foo, :bar, :baz]
      end

      context "継承された場合" do
        specify "メソッド一覧は継承される" do
          foo_item = define_and_create_item do
            export :foo
          end
          bar_item = define_and_create_item(foo_item.class) do
            export :bar
          end
          baz_item = define_and_create_item(bar_item.class) do
            export :baz
          end

          expect(foo_item.exported_methods).to match [:foo]
          expect(bar_item.exported_methods).to match [:foo, :bar]
          expect(baz_item.exported_methods).to match [:foo, :bar, :baz]
        end
      end
    end

    describe "#process_template" do
      include_context 'template engine'

      let(:code) { double('code') }

      it "テンプレートエンジンでテンプレートを処理し、コードを生成する" do
        engine = template_engine
        foo_item = define_and_create_item do
          template_engine engine
          main_code(:foo) { process_template }
        end
        bar_item = define_and_create_item(foo_item.class) do
          main_code(:bar) { process_template('bar.erb') }
        end

        allow(File).to receive(:binread).with(default_template_path).and_return(template)
        expect(code).to receive(:<<).with("#{foo_item.object_id}")
        foo_item.generate_main_code(:foo, code)

        allow(File).to receive(:binread).with('bar.erb').and_return(template)
        expect(code).to receive(:<<).with("#{bar_item.object_id}")
        bar_item.generate_main_code(:bar, code)
      end
    end
  end
end

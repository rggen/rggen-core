require  'spec_helper'

module RgGen::Core::Base
  describe ComponentFactory do
    def define_factory(&body)
      Class.new(ComponentFactory) do
        def create_component(parent, *_, &block)
          @target_component.new(parent, &block)
        end

        def post_create(component)
          component
        end

        def finalize(component)
        end

        body && class_eval(&body)
      end
    end

    let(:component_class) { Class.new(Component) }

    let(:parent) { Class.new(Component).new }

    let(:arguments) { [2, 1] }

    describe "#create" do
      let(:factory) { define_factory.new { |f| f.target_component component_class } }

      it "#target_componentで登録されたコンポーネントオブジェクトを生成する" do
        expect(factory.create(parent, *arguments)).to be_instance_of(component_class)
      end

      context "ルートファクトリのとき" do
        before { factory.root_factory }

        it "ルートコンポーネントを生成する" do
          expect(factory.create.parent).to be_nil
        end

        it "引数すべてに対して、#preprocessを実行し、引数の前処理を行う" do
          allow(factory).to receive(:preprocess).and_call_original
          factory.create(*arguments)
          expect(factory).to have_received(:preprocess).with(match(arguments))
        end

        it "#finalizeを実行し、仕上げ処理を行う" do
          allow(factory).to receive(:finalize)
          component = factory.create
          expect(factory).to have_received(:finalize).with(equal(component))
        end
      end

      context "ルートファクトリではないとき" do
        it "親コンポーネントの子コンポーネントを生成する" do
          expect(factory.create(parent).parent).to equal parent
        end

        it "#add_childを呼び出して、親コンポーネントに生成したコンポーネントを登録する" do
          allow(parent).to receive(:add_child).and_call_original
          component = factory.create(parent)
          expect(parent).to have_received(:add_child).with(equal(component))
        end

        it "先頭の親コンポーネントを除いた引数に対して、#preprocessを呼び出して、引数の前処理を行う" do
          allow(factory).to receive(:preprocess).and_call_original
          factory.create(parent, *arguments)
          expect(factory).to have_received(:preprocess).with(match(arguments))
        end

        it "仕上げ処理は行わない" do
          expect(factory).not_to receive(:finalize)
          factory.create(parent)
        end
      end

      context "子コンポーネントファクトリが登録されているとき" do
        let(:child_component_class) { Class.new(Component) }

        let(:factory) do
          define_factory {
            def create_children(component, *args)
              args[0].times { create_child(component, args[1]) }
            end
          }.new { |f|
            f.target_component component_class
            f.child_factory child_factory
          }
        end

        let(:child_factory) do
          define_factory.new { |f| f.target_component child_component_class }
        end

        it "子コンポーネントを含むコンポーネントオブジェクトを生成する" do
          expect(factory.create(parent, *arguments).children).to match [
            be_instance_of(child_component_class), be_instance_of(child_component_class)
          ]
        end

        context "生成したコンポーネントが子コンポーネントを必要としない場合" do
          before do
            allow_any_instance_of(component_class).to receive(:need_children?).and_return(false)
          end

          it "子コンポーネントを含まないコンポーネントオブジェクトを生成する" do
            expect(child_factory).not_to receive(:create)
            expect(factory.create(parent, *arguments).children).to be_empty
          end
        end
      end

      context "アイテムファクトリが登録されているとき" do
        let(:foo_item) { Class.new(Item) }

        let(:bar_item) { Class.new(Item) }

        let(:item_factory_class) do
          Class.new(ItemFactory) do
            def create(component, *args)
              create_item(component, *args)
            end
          end
        end

        let(:foo_item_factory) { item_factory_class.new(:foo) { |f| f.target_item foo_item } }

        let(:bar_item_factory) { item_factory_class.new(:bar) { |f| f.target_item bar_item } }

        let(:factory) do
          define_factory {
            def create_items(component, *args)
              @item_factories.each_value { |f| create_item(component, f, *args) }
            end
          }.new { |f|
            f.target_component Class.new(Component)
            f.item_factories(foo: foo_item_factory, bar: bar_item_factory)
          }
        end

        it "アイテムを含むコンポーネントオブジェクトを生成する" do
          expect(factory.create(parent).items).to match [be_instance_of(foo_item), be_instance_of(bar_item)]
        end
      end
    end
  end
end

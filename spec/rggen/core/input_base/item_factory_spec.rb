require 'spec_helper'

module RgGen::Core::InputBase
  describe ItemFactory do
    let(:item_name) { :item_name }

    let(:active_item) { Class.new(Item) { build {} } }
    let(:passive_item) { Class.new(Item) }

    describe "#create" do
      let(:component) { RgGen::Core::Base::Component.new }

      let(:active_factory) do
        ItemFactory.new(item_name) { |f| f.target_item active_item }
      end

      let(:passive_factory) do
        ItemFactory.new(item_name) { |f| f.target_item passive_item }
      end

      let(:input_value) { InputValue.new(:foo, position) }

      let(:position) { Struct.new(:x, :y).new(0, 1) }

      it "#create_itemを呼んで、アイテムを生成する" do
        expect(active_factory).to receive(:create_item).and_call_original
        expect(passive_factory).to receive(:create_item).and_call_original
        active_factory.create(component, :other_arg, input_value)
        passive_factory.create(component)
      end

      describe "アイテムの組み立て" do
        it "末尾の引数を用いて、アイテムの組み立てを行う" do
          expect_any_instance_of(active_item).to receive(:build).with(equal(input_value))
          active_factory.create(component, :other_arg, input_value)
        end

        context "入力データが空データの場合" do
          it "アイテムの組み立てを行わない" do
            expect_any_instance_of(active_item).not_to receive(:build)
            active_factory.create(component, :other_arg, NilValue)
          end
        end

        context "対象アイテムが受動アイテムの場合" do
          it "アイテムの組み立てを行わない" do
            expect_any_instance_of(passive_item).not_to receive(:build)
            passive_factory.create(component)
          end
        end
      end

      describe "入力値の変換" do
        let(:item_class) do
          Class.new(Item) do
            field :value
            build { |value| @value = value }
          end
        end

        let(:factory_class) do
          Class.new(ItemFactory) do
            convert_value { |value| upcase(value) }
            def upcase(value); value.upcase end
          end
        end

        let(:active_factory) do
          factory_class.new(item_name) { |f| f.target_item item_class }
        end

        let(:passive_factory) do
          factory_class.new(item_name) { |f| f.target_item passive_item }
        end

        let(:item) { active_factory.create(component, input_value) }

        it ".convert_valueで登録されたブロックを実行し、入力値の変換を行う" do
          expect(active_factory).to receive(:upcase).and_call_original
          expect(item.value).to eq :FOO
        end

        specify "変換後も位置情報は維持される" do
          expect(item.send(:position)).to eq position
        end

        specify "引数として与えられた入力値は変化しない" do
          active_factory.create(component, input_value)
          expect(input_value.value).to eq :foo
        end

        it "入力が空データの場合は、入力値の変換を行わない" do
          expect(active_factory).not_to receive(:upcase)
          active_factory.create(component, NilValue)
        end

        it "対象アイテムが受動アイテムの場合は、入力値の変換を行わない" do
          expect(passive_factory).not_to receive(:upcase)
          passive_factory.create(component, input_value)
        end
      end
    end

    describe "#active_item_factory?/#passive_item_factory?" do
      let(:simple_active_item_factory) do
        ItemFactory.new(item_name) { |f| f.target_item active_item }
      end

      let(:simple_passive_item_factory) do
        ItemFactory.new(item_name) { |f| f.target_item passive_item }
      end

      let(:multiple_items_factory) do
        ItemFactory.new(item_name) do |f|
          f.target_item passive_item
          f.target_items foo: active_item, bar: passive_item
        end
      end

      specify "能動アイテムを#target_itemに持つファクトリは能動アイテムファクトリ" do
        expect(simple_active_item_factory).to be_active_item_factory
        expect(simple_active_item_factory).not_to be_passive_item_factory
      end

      specify "受動アイテムを#target_itemに持つファクトリは受動アイテムファクトリ" do
        expect(simple_passive_item_factory).not_to be_active_item_factory
        expect(simple_passive_item_factory).to be_passive_item_factory
      end

      specify "#target_itemsを持つファクトリは能動アイテムファクトリ" do
        expect(multiple_items_factory).to be_active_item_factory
        expect(multiple_items_factory).not_to be_passive_item_factory
      end
    end
  end
end

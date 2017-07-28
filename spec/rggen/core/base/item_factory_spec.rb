require 'spec_helper'

module RgGen::Core::Base
  describe ItemFactory do
    let(:created_items) { [] }

    let(:item_class_a) do
      Class.new(Item).tap do |klass|
        allow(klass).to receive(:new).and_wrap_original do |m, *args, &block|
          m.call(*args, &block).tap { |item| created_items << item }
        end
      end
    end

    let(:item_class_b) do
      Class.new(Item).tap do |klass|
        allow(klass).to receive(:new).and_wrap_original do |m, *args, &block|
          m.call(*args, &block).tap { |item| created_items << item }
        end
      end
    end

    let(:item_class_c) do
      Class.new(Item).tap do |klass|
        allow(klass).to receive(:new).and_wrap_original do |m, *args, &block|
          m.call(*args, &block).tap { |item| created_items << item }
        end
      end
    end

    let(:factory_class) do
      Class.new(ItemFactory) do
        def create(component, *args, &block)
          create_item(component, *args, &block)
        end

        def select_target_item(arg)
          @target_items[arg]
        end
      end
    end

    let(:item_name) { :item_name }

    let(:item_factory) { factory_class.new(item_name) { |f| f.target_item item_class_a } }

    let(:component) { Component.new }

    describe "#create_item" do
      it "対象アイテムを生成し、コンポーネントに追加する" do
        allow(component).to receive(:add_item)
        item_factory.create_item(component)
        expect(component).to have_received(:add_item).with(item_name, equal(created_items.first))
      end

      it "生成したアイテムにアイテム名を付与する" do
        item_factory.create_item(component)
        expect(created_items.first.item_name).to eq item_name
      end

      it "生成したアイテムオブジェクトを引数にして、与えられたブロックを実行する" do
        created_item  = nil
        item_factory.create_item(component) { |item| created_item = item }
        expect(created_item).to equal(created_items.first)
      end

      context "target_itemsで対象アイテムクラス群が登録されているとき" do
        before do
          item_factory.target_items item_b: item_class_b
        end

        context "#select_target_itemがクラスを返す場合" do
          it "#select_target_itemで選択されたアイテムオブジェクトを生成する" do
            item_factory.create(component, :item_b)
            expect(created_items.first).to be_an_instance_of item_class_b
          end
        end

        context "#select_target_itemがクラスを返さない場合" do
          it "#target_itemで登録されたアイテムオブジェクトを生成する" do
            item_factory.create(component, :item_c)
            expect(created_items.first).to be_an_instance_of item_class_a
          end
        end
      end

      context "生成したアイテムオブジェクトが使用不可(Item#available?がfalseを返す)場合" do
        before do
          item_class_a.class_eval { available? { false } }
        end

        it "コンポーネントに生成したアイテムを追加しない" do
          expect(component).not_to receive(:add_item)
          item_factory.create(component)
        end

        it "与えられたブロックを実行しない" do
          expect { |b| item_factory.create(component, &b) }.not_to yield_control
        end
      end
    end
  end
end

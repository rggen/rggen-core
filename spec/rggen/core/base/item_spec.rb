require  'spec_helper'

module RgGen::Core::Base
  describe Item do
    let(:component) { Component.new }

    let(:item_class) { Class.new(Item) }

    let(:item_name) { :foo }

    let(:item) { item_class.new(component, item_name) }

    describe "#component" do
      it "オーナーコンポーネントを返す" do
        expect(item.component).to eql component
      end
    end

    describe "#item_name" do
      it "アイテム名を返す" do
        expect(item.item_name).to eq item_name
      end
    end

    describe ".define_helpers" do
      before do
        item_class.class_exec do
          define_helpers do
            def foo ; end
            def bar ; end
          end
        end
      end

      it "特異クラスにヘルパーメソッドを追加する" do
        expect(item_class.singleton_methods(false)).to match [:foo, :bar]
      end
    end

    describe "#available?" do
      context "通常の場合" do
        it "使用可能であることを示す" do
          expect(item).to be_available
        end
      end

      context ".available?で#available?が再定義された場合" do
        before do
          item_class.class_exec do
            available? { false }
          end
        end

        it "available?に与えたブロックの評価結果を返す" do
          expect(item).not_to be_available
        end
      end
    end
  end
end

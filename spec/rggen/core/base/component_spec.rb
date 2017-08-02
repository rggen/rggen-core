require 'spec_helper'

module RgGen::Core::Base
  describe Component do
    describe "#parent" do
      let(:parent) { Component.new }
      let(:component) { Component.new(parent) }

      it "親オブジェクトを返す" do
        expect(component.parent).to eql parent
      end
    end

    describe "#need_children?" do
      let(:components) do
        [
          Component.new,
          Component.new { |c| c.need_no_children }
        ]
      end

      it "子コンポーネントが必要かどうかを返す" do
        expect(components[0].need_children?).to be_truthy
        expect(components[1].need_children?).to be_falsey
      end
    end

    describe "#add_child" do
      let(:children) { Array.new(2) { Component.new(component) } }

      before do
        children.each { |c| component.add_child(c) }
      end

      context "子コンポーネントを必要とする場合" do
        let(:component) { Component.new }

        it "子オブジェクトを追加する" do
          expect(component.children).to match [eql(children[0]), eql(children[1])]
        end
      end

      context "子コンポーネントを必要としない場合" do
        let(:component) { Component.new { |c| c.need_no_children } }

        it "子コンポーネントの追加を行わない" do
          expect(component.children).to be_empty
        end
      end
    end

    describe "#level" do
      let(:parent) { Component.new }

      context "親オブジェクトがない場合" do
        it "0を返す" do
          expect(parent.level).to eq 0
        end
      end

      context "親オブジェクトがある場合" do
        let(:child) { Component.new(parent) }
        let(:grandchild) { Component.new(child) }

        it "parent.level + 1を返す" do
          expect(child.level     ).to eq 1
          expect(grandchild.level).to eq 2
        end
      end
    end

    describe "#add_item" do
      let(:component) { Component.new }

      let(:items) do
        [:foo, :bar].each_with_object({}) do |item_name, hash|
          hash[item_name] = Object.new.tap do |item|
            allow(item).to receive(:item_name).and_return(item_name)
          end
        end
      end

      before do
        items.each_value { |item| component.add_item(item) }
      end

      it "アイテムコンポーネントを追加する" do
        expect(component.items).to match [equal(items[:foo]), equal(items[:bar])]
      end

      specify "追加したアイテムは、アイテム名で参照できる" do
        expect(component.item(:foo)).to equal items[:foo]
        expect(component.item(:bar)).to equal items[:bar]
      end
    end
  end
end

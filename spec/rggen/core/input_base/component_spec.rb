require 'spec_helper'

module RgGen::Core::InputBase
  describe Component do
    describe "#add_item" do
      let(:component) { Component.new }

      let(:items) do
        [
          Class.new(Item) { field :foo, default: :foo; field :bar, default: :bar; }.new(component, :item_0),
          Class.new(Item) { field :baz, default: :baz }.new(component, :item_1)
        ]
      end

      before { items.each { |item| component.add_item(item) } }

      before do
        expect(items[0]).to receive(:foo).and_call_original
        expect(items[0]).to receive(:bar).and_call_original
        expect(items[1]).to receive(:baz).and_call_original
      end

      specify "アイテムの追加後、自身をレシーバとして、配下のアイテムのフィールドにアクセスできる" do
        expect(component.foo).to eq :foo
        expect(component.bar).to eq :bar
        expect(component.baz).to eq :baz
      end
    end

    describe "#fields" do
      let(:component) { Component.new }

      let(:items) do
        [
          Class.new(Item) { field :foo; field :bar}.new(component, :item_0),
          Class.new(Item) { field :baz }.new(component, :item_1)
        ]
      end

      before do
        items.each { |item| component.add_item(item) }
      end

      it "配下のアイテムが持つフィールドの一覧を返す" do
        expect(component.fields).to match [:foo, :bar, :baz]
      end
    end

    describe "#validate" do
      let(:component) { Component.new }

      let(:child_components) do
        Array.new(2) { Component.new(component).tap { |c| component.add_child(c) } }
      end

      let(:grandchild_component) do
        Array.new(4) do |i|
          parent = child_components[i / 2]
          Component.new(parent).tap { |c| parent.add_child(c) }
        end
      end

      let(:items) do
        [component, *child_components, *grandchild_component].flat_map.with_index do |c, i|
          Array.new(2) { |j| Item.new(c, "item_#{i}_#{j}").tap { |item| c.add_item(item) } }
        end
      end

      before do
        child_components.each { |c| expect(c).to receive(:validate).and_call_original }
        grandchild_component.each { |c| expect(c).to receive(:validate).and_call_original }
        items.each { |i| expect(i).to receive(:validate).and_call_original }
      end

      it "配下の全コンポーネント、アイテムの検査を行う" do
        component.validate
      end
    end
  end
end

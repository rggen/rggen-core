require 'spec_helper'

module RgGen::Core::InputBase
  describe ItemFactory do
    let(:item_name) { :item_name }

    let(:active_item) { Class.new(Item) { build {} } }

    let(:passive_item) { Class.new(Item) }

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

require 'spec_helper'

module RgGen::Core::Base
  describe HierarchicalItemAccessors do
    let(:item_class) do
      Class.new(Item) do
        include HierarchicalItemAccessors
        def initialize(component)
          super(component, :item)
          define_hierarchical_item_accessors
        end
      end
    end

    let(:register_map) { Component.new }

    let(:register_block) { Component.new(register_map) }

    let(:register) { Component.new(register_block) }

    let(:bit_field) { Component.new(register) }

    context "#componentの#levelが0の場合" do
      let(:item) { item_class.new(register_map) }

      describe "#hierarchy" do
        it ":register_mapを返す" do
          expect(item.hierarchy).to eq :register_map
        end
      end

      describe "#register_map" do
        it "#componentを返す" do
          expect(item.register_map).to equal register_map
        end
      end
    end

    context "#componentの#levelが1の場合" do
      let(:item) { item_class.new(register_block) }

      describe "#hierarchy" do
        it ":register_blockを返す" do
          expect(item.hierarchy).to eq :register_block
        end
      end

      describe "#register_map" do
        it "#register_blockの親オブジェクトを返す" do
          expect(item.register_map).to equal register_map
        end
      end

      describe "#register_block" do
        it "#componentを返す" do
          expect(item.register_block).to equal register_block
        end
      end
    end

    context "#componentの#levelが2の場合" do
      let(:item) { item_class.new(register) }

      describe "#hierarchy" do
        it ":registerを返す" do
          expect(item.hierarchy).to eq :register
        end
      end

      describe "#register_map" do
        it "#register_blockの親オブジェクトを返す" do
          expect(item.register_map).to equal register_map
        end
      end

      describe "#register_block" do
        it "#registerの親オブジェクトを返す" do
          expect(item.register_block).to equal register_block
        end
      end

      describe "#register" do
        it "#componentを返す" do
          expect(item.register).to equal register
        end
      end
    end

    context "#componentの#levelが3の場合" do
      let(:item) { item_class.new(bit_field) }

      describe "#hierarchy" do
        it ":bit_fieldを返す" do
          expect(item.hierarchy).to eq :bit_field
        end
      end

      describe "#register_map" do
        it "#register_blockの親オブジェクトを返す" do
          expect(item.register_map).to equal register_map
        end
      end

      describe "#register_block" do
        it "#registerの親オブジェクトを返す" do
          expect(item.register_block).to equal register_block
        end
      end

      describe "#register" do
        it "#bit_fieldの親オブジェクトを返す" do
          expect(item.register).to equal register
        end
      end

      describe "#bit_field" do
        it "#componentを返す" do
          expect(item.bit_field).to equal bit_field
        end
      end
    end
  end
end

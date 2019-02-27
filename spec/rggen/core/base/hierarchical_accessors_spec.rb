# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Base
  describe HierarchicalAccessors do
    before(:all) do
      klass = Class.new(Component) do
        include HierarchicalAccessors
        def initialize(parent = nil)
          super
          parent && parent.add_child(self)
          define_hierarchical_accessors
        end
      end

      @register_map = klass.new
      @register_blocks = Array.new(2) { klass.new(@register_map) }
      @registers = Array.new(2) { |i| Array.new(2) { klass.new(@register_blocks[i]) } }.flatten
      @bit_fiels = Array.new(4) { |i| Array.new(2) { klass.new(@registers[i]) } }.flatten
    end

    let(:register_map) { @register_map }

    let(:register_blocks) { @register_blocks }
    let(:register_block) { register_blocks.first }

    let(:registers) { @registers }
    let(:register) { registers.first }

    let(:bit_fields) { @bit_fiels }
    let(:bit_field) { bit_fields.first }

    context "#levelが0の場合" do
      describe "#hierarchy" do
        it ":register_mapを返す" do
          expect(register_map.hierarchy).to eq :register_map
        end
      end

      describe "#register_blocks" do
        it "配下のレジスタブロックオブジェクトを返す" do
          expect(register_map.register_blocks).to match [
            equal(register_blocks[0]), equal(register_blocks[1])
          ]
        end
      end

      describe "#registers" do
        it "配下のレジスタブロックオブジェクト一覧を返す" do
          expect(register_map.registers).to match [
            equal(registers[0]), equal(registers[1]), equal(registers[2]), equal(registers[3])
          ]
        end
      end

      describe "#bit_fields" do
        it "配下のビットフィールドオブジェクトを返す" do
          expect(register_map.bit_fields).to match [
            equal(bit_fields[0]), equal(bit_fields[1]), equal(bit_fields[2]), equal(bit_fields[3]),
            equal(bit_fields[4]), equal(bit_fields[5]), equal(bit_fields[6]), equal(bit_fields[7])
          ]
        end
      end
    end

    context "#levelが1の場合" do
      describe "#hierarchy" do
        it ":register_blockを返す" do
          expect(register_block.hierarchy).to eq :register_block
        end
      end

      describe "#register_map" do
        it "属するレジスタマップオブジェクトを返す" do
          expect(register_block.register_map).to equal register_map
        end
      end

      describe "#registers" do
        it "配下のレジスタオブジェクト一覧を返す" do
          expect(register_block.registers).to match [
            equal(registers[0]), equal(registers[1])
          ]
        end
      end

      describe "#bit_fields" do
        it "配下のビットフィールドオブジェクト一覧を返す" do
          expect(register_block.bit_fields).to match [
            equal(bit_fields[0]), equal(bit_fields[1]), equal(bit_fields[2]), equal(bit_fields[3])
          ]
        end
      end
    end

    context "#levelが2の場合" do
      describe "#hierarchy" do
        it ":registerを返す" do
          expect(register.hierarchy).to eq :register
        end
      end

      describe "#register_map" do
        it "属するレジスタマップオブジェクトを返す" do
          expect(register.register_map).to equal register_map
        end
      end

      describe "#register_block" do
        it "属するレジスタブロックオブジェクトを返す" do
          expect(register.register_block).to equal register_block
        end
      end

      describe "#bit_fields" do
        it "配下のビットフィールドオブジェクト一覧を返す" do
          expect(register.bit_fields).to match [
            equal(bit_fields[0]), equal(bit_fields[1])
          ]
        end
      end
    end

    context "#levelが3の場合" do
      describe "#hierarchy" do
        it ":registerを返す" do
          expect(bit_field.hierarchy).to eq :bit_field
        end
      end

      describe "#register_map" do
        it "属するレジスタマップオブジェクトを返す" do
          expect(bit_field.register_map).to equal register_map
        end
      end

      describe "#register_block" do
        it "属するレジスタブロックオブジェクトを返す" do
          expect(bit_field.register_block).to equal register_block
        end
      end

      describe "#register" do
        it "属するレジスタブオブジェクトを返す" do
          expect(bit_field.register).to equal register
        end
      end
    end
  end
end

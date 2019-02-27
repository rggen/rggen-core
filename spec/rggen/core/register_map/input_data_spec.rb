# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::RegisterMap
  describe InputData do
    let(:valid_value_lists) { [[:foo], [:bar], [:baz]] }

    let(:input_data) { InputData.new(hierarchy, valid_value_lists)}

    context "階層がregister_mapの場合" do
      let(:hierarchy) { :register_map }

      it "#register_blockで子入力データを追加できる" do
        expect {
          input_data.register_block { register }
        }.to change {
          input_data.children.size
        }.from(0).to(1)
      end

      specify "子入力データの階層はregister_block" do
        expect(
          input_data.register_block.hierarchy
        ).to eq :register_block
      end
    end

    context "階層が register_blockの場合" do
      let(:hierarchy) { :register_block }

      it "#registerで子入力データを追加できる" do
        expect {
          input_data.register { bit_field }
        }.to change {
          input_data.children.size
        }.from(0).to(1)
      end

      specify "子入力データの階層はregister" do
        expect(
          input_data.register.hierarchy
        ).to eq :register
      end
    end

    context "階層が registerの場合" do
      let(:hierarchy) { :register }

      it "#bit_fieldで子入力データを追加できる" do
        expect {
          input_data.bit_field { bar 0 }
        }.to change {
          input_data.children.size
        }.from(0).to(1)
      end

      specify "子入力データの階層はbit_field" do
        expect(
          input_data.bit_field.hierarchy
        ).to eq :bit_field
      end
    end
  end
end

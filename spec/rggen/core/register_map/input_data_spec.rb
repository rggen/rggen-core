# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::RegisterMap
  describe RegisterMapData do
    let(:valid_value_lists) { [[], [:foo], [:bar], [:baz]] }

    let(:input_data) { RegisterMapData.new(valid_value_lists) }

    it '#register_blockで子入力データを追加できる' do
      expect {
        input_data.register_block {}
      }.to change {
        input_data.children.size
      }.from(0).to(1)
    end

    specify '子入力データのクラスはRegisterBlockDataである' do
      input_data.register_block {}
      expect(input_data.children[0]).to be_instance_of(RegisterBlockData)
    end
  end

  describe RegisterBlockData do
    let(:valid_value_lists) { [[:foo], [:bar], [:baz]] }

    let(:input_data) { RegisterBlockData.new(valid_value_lists) }

    it '#registerで子入力データを追加できる' do
      expect {
        input_data.register {}
      }.to change {
        input_data.children.size
      }.from(0).to(1)
    end

    specify '子入力データのクラスはRegisterDataである' do
      input_data.register {}
      expect(input_data.children[0]).to be_instance_of(RegisterData)
    end
  end

  describe RegisterData do
    let(:valid_value_lists) { [[:foo], [:bar]] }

    let(:input_data) { RegisterData.new(valid_value_lists) }

    it '#bit_fieldで子入力データを追加できる' do
      expect {
        input_data.bit_field {}
      }.to change {
        input_data.children.size
      }.from(0).to(1)
    end

    specify '子入力データのクラスはBitFieldDataである' do
      input_data.bit_field {}
      expect(input_data.children[0]).to be_instance_of(BitFieldData)
    end
  end
end

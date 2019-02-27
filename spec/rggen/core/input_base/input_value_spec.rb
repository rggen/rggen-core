# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::InputBase
  describe InputValue do
    let(:position) { Struct.new(:x, :y).new(0, 1) }

    let(:string) { 'foo' }
    let(:string_value) { InputValue.new(string, position) }

    let(:symbol) { :foo }
    let(:symbol_value) { InputValue.new(symbol, position) }

    let(:object) { Object.new }
    let(:object_value) { InputValue.new(object, position) }

    let(:nil_value) { InputValue.new(nil, position) }

    let(:empty_string_value) { InputValue.new('', position) }

    let(:empty_symbol_value) { InputValue.new(:'', position) }

    it "入力値を保持する" do
      expect(string_value.value).to be string
      expect(symbol_value.value).to be symbol
      expect(object_value.value).to be object
    end

    it "入力値の位置情報を保持する" do
      expect(string_value.position).to be position
      expect(symbol_value.position).to be position
      expect(object_value.position).to be position
    end

    describe "#empty_value?" do
      specify "#nil?が真を返す入力値は空の入力値" do
        expect(nil_value).to be_empty_value
      end

      specify "#empty?が真を返す入力値は空の入力値" do
        expect(empty_string_value).to be_empty_value
        expect(empty_symbol_value).to be_empty_value
      end

      specify "上記以外は空の入力値ではない" do
        expect(string_value).not_to be_empty_value
        expect(symbol_value).not_to be_empty_value
        expect(object_value).not_to be_empty_value
      end
    end
  end

  describe NilValue do
    it "空の入力値である" do
      expect(NilValue).to be_empty_value
    end
  end
end

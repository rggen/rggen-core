# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::InputValue do
  let(:position) { Struct.new(:x, :y).new(0, 1) }

  let(:string) { 'foo' }
  let(:string_value) { described_class.new(string, position) }

  let(:symbol) { :foo }
  let(:symbol_value) { described_class.new(symbol, position) }

  let(:object) { Object.new }
  let(:object_value) { described_class.new(object, position) }

  let(:nil_value) { described_class.new(nil, position) }

  let(:empty_string_values) do
    [described_class.new('', position), described_class.new(" \t\n", position)]
  end

  let(:empty_symbol_value) { described_class.new(:'', position) }

  it '入力値を保持する' do
    expect(string_value.value).to eq string
    expect(symbol_value.value).to eq symbol
    expect(object_value.value).to be object
  end

  it '入力値の位置情報を保持する' do
    expect(string_value.position).to be position
    expect(symbol_value.position).to be position
    expect(object_value.position).to be position
  end

  context '入力値が文字列の場合' do
    let(:string_value_with_white_speces) do
      described_class.new(" \n#{string}\t ", position)
    end

    specify '両端の空白を削除した値を入力値とする' do
      expect(string_value_with_white_speces.value).to eq string
    end
  end

  describe '#empty_value?' do
    specify '#nil?が真を返す入力値は空の入力値' do
      expect(nil_value).to be_empty_value
    end

    specify '#empty?が真を返す入力値は空の入力値' do
      expect(empty_string_values[0]).to be_empty_value
      expect(empty_string_values[1]).to be_empty_value
      expect(empty_symbol_value).to be_empty_value
    end

    specify '上記以外は空の入力値ではない' do
      expect(string_value).not_to be_empty_value
      expect(symbol_value).not_to be_empty_value
      expect(object_value).not_to be_empty_value
    end
  end
end

RSpec.describe RgGen::Core::InputBase::NAValue do
  let(:na_value) { RgGen::Core::InputBase::NAValue }

  it '空の入力値である' do
    expect(na_value).to be_empty_value
  end

  it '無効な値である' do
    expect(na_value).not_to be_available
  end
end

# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::InputValue do
  let(:position) { Struct.new(:x, :y).new(0, 1) }

  let(:integer) { 1 }
  let(:integer_value) { described_class.new(integer, position) }

  let(:string) { 'foo' }
  let(:string_value) { described_class.new(string, position) }

  let(:symbol) { :foo }
  let(:symbol_value) { described_class.new(symbol, position) }

  let(:array) { [] }
  let(:array_value) { described_class.new(array, position) }

  let(:hash) { {} }
  let(:hash_value) { described_class.new(hash, position) }

  let(:object) { Object.new }
  let(:object_value) { described_class.new(object, position) }

  let(:nil_value) { described_class.new(nil, position) }

  let(:empty_string_values) do
    [described_class.new('', position), described_class.new(" \t\n", position)]
  end

  let(:empty_symbol_value) { described_class.new(:'', position) }

  it '入力値を保持する' do
    expect(integer_value.value).to eq integer
    expect(string_value.value).to eq string
    expect(symbol_value.value).to eq symbol
    expect(object_value.value).to be object
  end

  it '入力値の位置情報を保持する' do
    expect(integer_value.position).to eq position
    expect(string_value.position).to be position
    expect(symbol_value.position).to be position
    expect(object_value.position).to be position
  end

  it '入力値が持つメソッドを呼び出せる' do
    expect(integer_value.next).to eq integer.next
    expect(string_value.capitalize).to eq string.capitalize
    expect(symbol_value.size).to eq symbol.size
    array_value << 1
    expect(array_value).to match([1])
    hash_value[:foo] = 1
    expect(hash_value).to match(foo: 1)
  end

  describe '#==' do
    it '入力値と右辺値が一致するかを返す' do
      expect(integer_value).to eq integer
      expect(integer_value).to eq described_class.new(integer, position)

      expect(string_value).to eq string
      expect(string_value).to eq described_class.new(string, position)

      expect(symbol_value).to eq symbol
      expect(symbol_value).to eq described_class.new(symbol, position)

      expect(array_value).to eq array
      expect(array_value).to eq described_class.new(array, position)

      expect(hash_value).to eq hash
      expect(hash_value).to eq described_class.new(hash, position)
    end
  end

  describe '#match_class?' do
    it '入力値が指定されたクラスのインスタンスかどうかを返す' do
      expect(integer_value.match_class?(Integer)).to be true
      expect(integer_value.match_class?(String)).to be false

      expect(string_value.match_class?(String)).to be true
      expect(string_value.match_class?(Symbol)).to be false

      expect(symbol_value.match_class?(Symbol)).to be true
      expect(symbol_value.match_class?(Array)).to be false

      expect(array_value.match_class?(Array)).to be true
      expect(array_value.match_class?(Hash)).to be false

      expect(hash_value.match_class?(Hash)).to be true
      expect(hash_value.match_class?(Integer)).to be false
    end
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
      expect(array_value).to be_empty_value
      expect(hash_value).to be_empty_value
    end

    specify '上記以外は空の入力値ではない' do
      expect(integer_value).not_to be_empty_value
      expect(string_value).not_to be_empty_value
      expect(symbol_value).not_to be_empty_value
      expect(object_value).not_to be_empty_value
      array_value << 1
      expect(array_value).not_to be_empty_value
      hash_value[:foo] = 1
      expect(hash_value).not_to be_empty_value
    end
  end

  describe '#with_options?' do
    let(:value) do
      [integer, string, symbol, array, hash, object, nil].sample
    end

    let(:options) do
      [[], nil, false, Object.new]
    end

    let(:value_with_options) do
      described_class.new(value, options, position)
    end

    let(:value_without_options) do
      described_class.new(value, position)
    end

    it '入力値がオプションを持つかどうかを示す' do
      expect(value_with_options).to be_with_options
      expect(value_without_options).not_to be_with_options
    end
  end

  describe 'Kernel#Integer' do
    let(:hex_string_value) do
      described_class.new('0x10', position)
    end

    it '入力値を対象に整数への変換を行う' do
      expect(Integer(hex_string_value)).to eq 16
      expect(Integer(hex_string_value, 16)).to eq 16

      expect {
        Integer(string_value)
      }.to raise_error ArgumentError

      expect {
        Integer(array_value)
      }.to raise_error TypeError
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

# frozen_string_literal: true

RSpec.describe RgGen::Core::Utility::TypeChecker do
  def input_value(value)
    RgGen::Core::InputBase::InputValue.new(value, nil)
  end

  let(:checker) do
    described_class
  end

  let(:string_value) do
    'foo'
  end

  let(:symbol_value) do
    :foo
  end

  let(:integer_value) do
    1
  end

  let(:array_value) do
    []
  end

  let(:hash_value) do
    {}
  end

  let(:object_value) do
    Object.new
  end

  describe '#string?' do
    it '与えられた引数が文字列かどうかを返す' do
      expect(checker.string?(string_value)).to be true
      expect(checker.string?(input_value(string_value))).to be true

      expect(checker.string?(symbol_value)).to be false
      expect(checker.string?(input_value(symbol_value))).to be false

      expect(checker.string?(integer_value)).to be false
      expect(checker.string?(input_value(integer_value))).to be false

      expect(checker.string?(array_value)).to be false
      expect(checker.string?(input_value(array_value))).to be false

      expect(checker.string?(hash_value)).to be false
      expect(checker.string?(input_value(hash_value))).to be false

      expect(checker.string?(object_value)).to be false
      expect(checker.string?(input_value(object_value))).to be false
    end
  end

  describe '#symbol?' do
    it '与えられた引数がシンボルかどうかを返す' do
      expect(checker.symbol?(string_value)).to be false
      expect(checker.symbol?(input_value(string_value))).to be false

      expect(checker.symbol?(symbol_value)).to be true
      expect(checker.symbol?(input_value(symbol_value))).to be true

      expect(checker.symbol?(integer_value)).to be false
      expect(checker.symbol?(input_value(integer_value))).to be false

      expect(checker.symbol?(array_value)).to be false
      expect(checker.symbol?(input_value(array_value))).to be false

      expect(checker.symbol?(hash_value)).to be false
      expect(checker.symbol?(input_value(hash_value))).to be false

      expect(checker.symbol?(object_value)).to be false
      expect(checker.symbol?(input_value(object_value))).to be false
    end
  end

  describe '#integer?' do
    it '与えられた引数が整数かどうかを返す' do
      expect(checker.integer?(string_value)).to be false
      expect(checker.integer?(input_value(string_value))).to be false

      expect(checker.integer?(symbol_value)).to be false
      expect(checker.integer?(input_value(symbol_value))).to be false

      expect(checker.integer?(integer_value)).to be true
      expect(checker.integer?(input_value(integer_value))).to be true

      expect(checker.integer?(array_value)).to be false
      expect(checker.integer?(input_value(array_value))).to be false

      expect(checker.integer?(hash_value)).to be false
      expect(checker.integer?(input_value(hash_value))).to be false

      expect(checker.integer?(object_value)).to be false
      expect(checker.integer?(input_value(object_value))).to be false
    end
  end

  describe '#array?' do
    it '与えられた引数が配列かどうかを返す' do
      expect(checker.array?(string_value)).to be false
      expect(checker.array?(input_value(string_value))).to be false

      expect(checker.array?(symbol_value)).to be false
      expect(checker.array?(input_value(symbol_value))).to be false

      expect(checker.array?(integer_value)).to be false
      expect(checker.array?(input_value(integer_value))).to be false

      expect(checker.array?(array_value)).to be true
      expect(checker.array?(input_value(array_value))).to be true

      expect(checker.array?(hash_value)).to be false
      expect(checker.array?(input_value(hash_value))).to be false

      expect(checker.array?(object_value)).to be false
      expect(checker.array?(input_value(object_value))).to be false
    end
  end

  describe '#hash?' do
    it '与えられた引数が連想配列かどうかを返す' do
      expect(checker.hash?(string_value)).to be false
      expect(checker.hash?(input_value(string_value))).to be false

      expect(checker.hash?(symbol_value)).to be false
      expect(checker.hash?(input_value(symbol_value))).to be false

      expect(checker.hash?(integer_value)).to be false
      expect(checker.hash?(input_value(integer_value))).to be false

      expect(checker.hash?(array_value)).to be false
      expect(checker.hash?(input_value(array_value))).to be false

      expect(checker.hash?(hash_value)).to be true
      expect(checker.hash?(input_value(hash_value))).to be true

      expect(checker.hash?(object_value)).to be false
      expect(checker.hash?(input_value(object_value))).to be false
    end
  end
end

# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::InputDataExtractor do
  def create_extractor(target_layers, target_value, &body)
    Class.new(described_class) { extract(&body) }.new(target_layers, target_value)
  end

  describe '#target_value?' do
    context 'target_layersの指定がある場合' do
      specify '指定された階層のtarget_valueが抽出対象の値' do
        extractor = create_extractor(:foo, :fizz)
        expect(extractor.target_value?(:foo, :fizz)).to be true
        expect(extractor.target_value?(:bar, :fizz)).to be false
        expect(extractor.target_value?(:baz, :fizz)).to be false
        expect(extractor.target_value?(:foo, :buzz)).to be false
        expect(extractor.target_value?(:bar, :buzz)).to be false
        expect(extractor.target_value?(:baz, :buzz)).to be false

        extractor = create_extractor([:bar, :baz], :buzz)
        expect(extractor.target_value?(:foo, :fizz)).to be false
        expect(extractor.target_value?(:bar, :fizz)).to be false
        expect(extractor.target_value?(:baz, :fizz)).to be false
        expect(extractor.target_value?(:foo, :buzz)).to be false
        expect(extractor.target_value?(:bar, :buzz)).to be true
        expect(extractor.target_value?(:baz, :buzz)).to be true
      end
    end

    context 'tareget_layerの指定がない場合' do
      specify '任意の階層が対象の階層' do
        extractor = create_extractor(nil, :fizz)
        expect(extractor.target_value?(:foo, :fizz)).to be true
        expect(extractor.target_value?(:bar, :fizz)).to be true
        expect(extractor.target_value?(:baz, :fizz)).to be true
        expect(extractor.target_value?(:foo, :buzz)).to be false
        expect(extractor.target_value?(:bar, :buzz)).to be false
        expect(extractor.target_value?(:baz, :buzz)).to be false
      end
    end
  end

  describe '#extract' do
    let(:input_data) { { fizz: 0, buzz: 1, fizzbuzz: 2 } }

    it '.extractで登録されたブロックを実行し、入力データから値の抽出を行う' do
      fizz_extractor = create_extractor(:foo, :fizz) { |input| input[:fizz] }
      expect(fizz_extractor.extract(input_data)).to eq input_data[:fizz]

      buzz_extractor = create_extractor(:foo, :buzz) { |input| input[:buzz] }
      expect(buzz_extractor.extract(input_data)).to eq input_data[:buzz]
    end
  end
end

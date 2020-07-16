# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::InputDataExtractor do
  def create_extractor(target_layers = nil, &body)
    Class.new(described_class) { extract(&body) }.new(target_layers)
  end

  describe '#target_layer?' do
    context 'target_layersの指定がある場合' do
      specify '指定された階層が対象の階層' do
        extractor = create_extractor(:foo)
        expect(extractor.target_layer?(:foo)).to be true
        expect(extractor.target_layer?(:bar)).to be false
        expect(extractor.target_layer?(:baz)).to be false

        extractor = create_extractor([:bar, :baz])
        expect(extractor.target_layer?(:foo)).to be false
        expect(extractor.target_layer?(:bar)).to be true
        expect(extractor.target_layer?(:baz)).to be true
      end
    end

    context 'tareget_layerの指定がない場合' do
      specify '任意の階層が対象の階層' do
        extractor = create_extractor
        expect(extractor.target_layer?(:foo)).to be true
        expect(extractor.target_layer?(:bar)).to be true
        expect(extractor.target_layer?(:baz)).to be true
      end
    end
  end

  describe '#extract' do
    let(:input_data) { { fizz: 0, buzz: 1, fizzbuzz: 2 } }

    it '.extractで登録されたブロックを実行し、入力データから値の抽出を行う' do
      fizz_extractor = create_extractor { |input| input[:fizz] }
      expect(fizz_extractor.extract(input_data)).to eq input_data[:fizz]

      buzz_extractor = create_extractor { |input| input[:buzz] }
      expect(buzz_extractor.extract(input_data)).to eq input_data[:buzz]
    end
  end
end

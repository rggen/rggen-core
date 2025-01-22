# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::HashListParser do
  let(:parser) do
    described_class.new
  end

  let(:position) do
    Struct.new(:x, :y).new(0, 1)
  end

  def parse(value)
    input_value = RgGen::Core::InputBase::InputValue.new(value, position)
    parser.parse(input_value)[0]
  end

  def match_result(value)
    matchers = Array(value).map { |v| match(v) }
    match(matchers)
  end

  describe '#parse' do
    context '入力が空の場合' do
      it '空の配列を返す' do
        expect(parse(nil)).to match([])
        expect(parse([])).to match([])
        expect(parse({})).to match([])
        expect(parse('')).to match([])
      end
    end

    context '入力がハッシュの配列の場合' do
      it '入力をそのまま結果として返す' do
        value = [
          { foo: 0, bar: 1 },
          { foo: 2, bar: 3, baz: 4 }
        ]
        expect(parse(value)).to match_result(value)
      end
    end

    context '入力がハッシュの場合' do
      it '配列に入れて返す' do
        value = { foo: 0, bar: 1 }
        expect(parse(value)).to match_result([value])
      end
    end

    context '入力が文字列の場合' do
      specify 'キーと値は:で区切られる' do
        value = 'foo : 0'
        expect(parse(value)).to match_result([{ 'foo' => '0' }])
      end

      specify '要素間は,または改行文字で区切られる' do
        value = ['foo: 0', 'bar: 1', 'baz: 2'].inject{ |v, e| v + [',', "\n"].sample + e }
        expect(parse(value)).to match_result([{ 'foo' => '0', 'bar' => '1', 'baz' => '2'}])
      end

      specify 'ハッシュ間は空行で区切られる' do
        value = "foo: 0\n\nfoo: 1 \n\n\nfoo: 2 \n   \n foo: 3"
        expect(parse(value)).to match_result([
          { 'foo' => '0' }, { 'foo' => '1' },
          { 'foo' => '2' }, { 'foo' => '3' }
        ])
      end

      specify '文字列の配列も受け入れ可能である' do
        value = ['foo: 0', 'foo: 1', 'foo: 2', 'foo: 3']
        expect(parse(value)).to match_result([
          { 'foo' => '0' }, { 'foo' => '1' },
          { 'foo' => '2' }, { 'foo' => '3' }
        ])
      end
    end

    context '入力がハッシュに変換できない場合' do
      it 'パーサー生成時に指定したクラスで例外を上げる' do
        ['foo', 'foo 1', 'foo: 1, bar', 1, true, false, Object.new].each do |value|
          expect {
            parse(value)
          }.to raise_source_error "cannot convert #{value.inspect} into hash", position

          expect {
            parse([value])
          }.to raise_source_error "cannot convert #{value.inspect} into hash", position
        end
      end
    end
  end
end

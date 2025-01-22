# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::OptionHashParser do
  let(:position) do
    Struct.new(:x, :y).new(1, 2)
  end

  def parser(allowed_options: [:foo, :bar, :baz], multiple_values: false)
    described_class
      .new(allowed_options: allowed_options, multiple_values: multiple_values)
  end

  def create_input_value(value)
    RgGen::Core::InputBase::InputValue.new(value, position)
  end

  def match_result(value, options)
    matcher =
      if value.is_a?(Array)
        value.map { |v| match_value(v) }
      else
        match_value(value)
      end
    match([matcher, options])
  end

  describe '#parse' do
    context 'オプションが未指定の場合' do
      it '入力値と空のハッシュを返す' do
        input_value = create_input_value(nil)
        expect(parser.parse(input_value)).to match_result(nil, {})
        expect(parser(multiple_values: true).parse(input_value)).to match_result([], {})

        input_value = create_input_value([])
        expect(parser.parse(input_value)).to match_result(nil, {})
        expect(parser(multiple_values: true).parse(input_value)).to match_result([], {})

        input_value = create_input_value(0)
        expect(parser.parse(input_value)).to match_result(0, {})
        expect(parser(multiple_values: true).parse(input_value)).to match_result([0], {})

        input_value = create_input_value([0])
        expect(parser.parse(input_value)).to match_result(0, {})
        expect(parser(multiple_values: true).parse(input_value)).to match_result([0], {})

        input_value = create_input_value('')
        expect(parser.parse(input_value)).to match_result(nil, {})
        expect(parser(multiple_values: true).parse(input_value)).to match_result([], {})

        input_value = create_input_value('0')
        expect(parser.parse(input_value)).to match_result('0', {})
        expect(parser(multiple_values: true).parse(input_value)).to match_result(['0'], {})

        input_value = create_input_value('0:')
        expect(parser.parse(input_value)).to match_result('0', {})
        expect(parser(multiple_values: true).parse(input_value)).to match_result(['0'], {})
      end
    end

    context '入力値が配列で与えられた場合' do
      it 'ハッシュをオプションとして返す' do
        input_value = create_input_value([0, foo: 1])
        expect(parser.parse(input_value)).to match_result(0, { foo: 1 })

        input_value = create_input_value([0, foo: 1, bar: 2])
        expect(parser.parse(input_value)).to match_result(0, { foo: 1, bar: 2 })

        input_value = create_input_value([0, { foo: 1 }, { bar: 2 }])
        expect(parser.parse(input_value)).to match_result(0, { foo: 1, bar: 2 })
      end
    end

    context '入力値が文字列で与えられた場合' do
      specify '入力値とオプションは:で区切られる' do
        input_value = create_input_value('0: foo: 1')
        expect(parser.parse(input_value)).to match_result('0', { foo: '1' })
      end

      specify '入力値およびオプションはコンマまたは改行で区切られる' do
        options = ['foo: 1', 'bar: 2', 'baz: 3'].inject { |s, o| s + [',', "\n"].sample + o }
        input_value = create_input_value("0: #{options}")
        expect(parser.parse(input_value)).to match_result('0', { foo: '1', bar: '2' , baz: '3' })

        values = ['0', '1', '2'].inject { |s, v| s + [',', "\n"].sample + v }
        options = ['foo: 3', 'bar: 4', 'baz: 5'].inject { |s, o| s + [',', "\n"].sample + o }
        input_value = create_input_value("#{values}: #{options}")
        expect(parser(multiple_values: true).parse(input_value)).to match_result(['0', '1', '2'], { foo: '3', bar: '4' , baz: '5' })
      end
    end

    specify 'キーが文字列の場合、シンボルに変換する' do
      input_value = create_input_value([0, {'foo' => 1}])
      expect(parser.parse(input_value)).to match_result(0, { foo: 1 })
    end
  end

  context '複数個の入力値が指定され' do
    context 'multipe_valuesの指定がある場合' do
      specify '複数の入力値を取ることができる' do
        input_value = create_input_value([0, 1])
        expect(parser(multiple_values: true).parse(input_value)).to match_result([0, 1], {})

        input_value = create_input_value([0, 1, foo: 2, bar: 3])
        expect(parser(multiple_values: true).parse(input_value)).to match_result([0, 1], { foo: 2, bar: 3 })

        input_value = create_input_value([0, { foo: 1 }, 2, { bar: 3 }])
        expect(parser(multiple_values: true).parse(input_value)).to match_result([0, 2], { foo: 1, bar: 3 })

        input_value = create_input_value('0, 1')
        expect(parser(multiple_values: true).parse(input_value)).to match_result(['0', '1'], {})

        input_value = create_input_value('0, 1: foo: 2, bar: 3')
        expect(parser(multiple_values: true).parse(input_value)).to match_result(['0', '1'], { foo: '2', bar: '3' })
      end
    end

    context 'multiple_valuesの指定がない場合' do
      it 'パーサー生成時に指定したクラスで例外を上げる' do
        values = ['0', '1']

        input_value = create_input_value(values.join(','))
        expect {
          parser.parse(input_value)
        }.to raise_source_error "multiple input values are given: #{values}", position

        input_value = create_input_value("#{values.join(',')}: foo: 2, bar: 3")
        expect {
          parser.parse(input_value)
        }.to raise_source_error "multiple input values are given: #{values}", position
      end
    end
  end

  context '入力オプションがHashに変換できない場合' do
    it 'パーサー生成時に指定したクラスで例外を上げる' do
      [nil, true, false, 0, 'foo', :foo, [], [:foo]].each do |value|
        input_value = create_input_value([0, { foo: 1 }, value, { bar: 2 }])
        expect {
          parser.parse(input_value)
        }.to raise_source_error "invalid option is given: #{value.inspect}", position
      end

      options = 'foo: 1, bar'
      input_value = create_input_value("0: #{options}")
      expect {
        parser.parse(input_value)
      }.to raise_source_error "invalid options are given: #{options.inspect}", position
    end
  end

  context 'オプションのみが与えらえれた場合' do
    it 'パーサー生成時に指定したクラスで例外を上げる' do
      options = { foo: 0, bar: 1 }
      input_value = create_input_value(options)
      expect {
        parser.parse(input_value)
      }.to raise_source_error "no input values are given: #{options.inspect}", position

      options = [{ foo: 0, bar: 1 }]
      input_value = create_input_value(options)
      expect {
        parser.parse(input_value)
      }.to raise_source_error "no input values are given: #{options.inspect}", position

      options = ':foo: 0, bar: 1'
      input_value = create_input_value(options)
      expect {
        parser.parse(input_value)
      }.to raise_source_error "no input values are given: #{options.inspect}", position
    end
  end

  context '許可されたオプション以外のオプションが指定された場合' do
    it 'パーサー生成時に指定したクラスで例外を上げる' do
      input_value = create_input_value([0, foo: 1, fizz: 2, bar: 3, buzz: 4])
      expect {
        parser.parse(input_value)
      }.to raise_source_error "unknown options are given: #{[:fizz, :buzz]}", position
    end
  end

  context '受け入れ可能オプションの指定がない場合' do
    it '任意のオプションを受け付けられる' do
      value = 0
      options = { foo: 1, fizz: 2, bar: 3, buzz: 4 }
      input_value = create_input_value([value, options])

      expect(parser(allowed_options: nil).parse(input_value)).to match_result(value, options)
      expect(parser(allowed_options: []).parse(input_value)).to match_result(value, options)
    end
  end
end

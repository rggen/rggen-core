# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::OptionArrayParser do
  let(:parser) do
    described_class.new
  end

  let(:position) do
    Struct.new(:x, :y).new(0, 1)
  end

  def create_input_value(value)
    RgGen::Core::InputBase::InputValue.new(value, position)
  end

  def match_result(value, options)
    match([match_value(value), options])
  end

  describe '#parse' do
    context 'オプションが未指定の場合' do
      it '入力値と空の配列を返す' do
        input_value = create_input_value(:foo)
        expect(parser.parse(input_value)).to match_result(:foo, [])

        input_value = create_input_value([:foo])
        expect(parser.parse(input_value)).to match_result(:foo, [])

        input_value = create_input_value('foo')
        expect(parser.parse(input_value)).to match_result('foo', [])

        input_value = create_input_value('foo:')
        expect(parser.parse(input_value)).to match_result('foo', [])
      end
    end

    context '入力値が配列で与えられた場合' do
      it '先頭を入力値、残りをオプションとして返す' do
        value = :foo
        options = [:bar, [:baz, 1], :qux]
        input_value = create_input_value([value, *options])

        expect(parser.parse(input_value)).to match_result(value, options)
      end
    end

    context '入力が文字列で与えられた場合' do
      specify '入力値とオプションは:で区切られる' do
        value = 'foo'
        options = 'bar'
        input_value = create_input_value("#{value}:#{options}")

        expect(parser.parse(input_value)).to match_result(value, [options])
      end

      specify 'オプション間はコンマまたは改行で区切られる' do
        value = 'foo'
        options = ['bar', 'baz', 'qux']
        options_string = options.inject { |s, o| s + [',', "\n"].sample + o }
        input_value = create_input_value("#{value}:#{options_string}")

        expect(parser.parse(input_value)).to match_result(value, options)
      end

      specify 'オプション名と値はコロンで区切られる' do
        value = 'foo'
        options = ['bar', ['baz', '1'], 'qux']
        option_string = options.map { |o| Array(o).join(':') }.join([',', "\n"].sample)
        input_value = create_input_value("#{value}:#{option_string}")

        expect(parser.parse(input_value)).to match_result(value, options)
      end
    end
  end
end

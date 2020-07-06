# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::InputMatcher do
  def create_matcher(pattern_or_patterns, **options, &conveter)
    described_class.new(pattern_or_patterns, **options, &conveter)
  end

  describe '#match' do
    it '指定された入力と、生成時に与えられた正規表現とでマッチングを行う' do
      expect(create_matcher(/foo/).match('foo')).to be_truthy
      expect(create_matcher(/foo/).match(:foo )).to be_truthy
      expect(create_matcher(/foo/).match('bar')).to be_falsey
      expect(create_matcher(/1/  ).match(1    )).to be_truthy

      expect(create_matcher([/foo/, { bar: /bar/, baz: /baz/ }, /qux/]).match('foo')).to be_truthy
      expect(create_matcher([/foo/, { bar: /bar/, baz: /baz/ }, /qux/]).match('bar')).to be_truthy
      expect(create_matcher([/foo/, { bar: /bar/, baz: /baz/ }, /qux/]).match('baz')).to be_truthy
      expect(create_matcher([/foo/, { bar: /bar/, baz: /baz/ }, /qux/]).match('qux')).to be_truthy
      expect(create_matcher([/foo/, { bar: /bar/, baz: /baz/ }, /qux/]).match('abc')).to be_falsey
    end

    context '入力がマッチした場合' do
      it 'MatchDataと一致したパターンのインデックスを返す' do
        match_data, index = create_matcher(/(foo)/).match('foo')
        expect(match_data)
          .to be_instance_of(MatchData)
          .and have_attributes(captures: match(['foo']))
        expect(index).to eq 0

        match_data, index = create_matcher([/(foo)/, { bar: /(bar)/}, /(baz)/]).match('foo')
        expect(match_data)
          .to be_instance_of(MatchData)
          .and have_attributes(captures: match(['foo']))
        expect(index).to eq 0

        match_data, index = create_matcher([/(foo)/, { bar: /(bar)/}, /(baz)/]).match('bar')
        expect(match_data)
          .to be_instance_of(MatchData)
          .and have_attributes(captures: match(['bar']))
        expect(index).to eq :bar

        match_data, index = create_matcher([/(foo)/, { bar: /(bar)/}, /(baz)/]).match('baz')
        expect(match_data)
          .to be_instance_of(MatchData)
          .and have_attributes(captures: match(['baz']))
        expect(index).to eq 2
      end
    end

    context '正規表現が複数個与えられた場合' do
      it '一致長が最長の結果を返す' do
        match_data, index = create_matcher([/(foo)/, /(foobar)/], match_wholly: false).match('foobar')
        expect(match_data.captures[0]).to eq 'foobar'
        expect(index).to eq 1
      end
    end

    context '入力がマッチし、生成時にブロックが与えられている場合' do
      specify 'ブロックは MatchDataを受け取る' do
        expect { |b|
          create_matcher(/foo/, &b).match('foo')
        }.to yield_with_args(MatchData)
      end

      it 'ブロックの評価結果を返す' do
        match_data, = create_matcher(/(foo)(bar)/) { |m| m.captures.map(&:upcase) }.match('foobar')
        expect(match_data).to match ['FOO', 'BAR']
      end
    end

    describe 'match_whollyオプション' do
      context 'trueが設定された場合' do
        let(:matcher) { create_matcher(/foo/, match_wholly: true) }

        it '与えられたパターンを入力の全体に対するパターンとして、マッチングを行う' do
          expect(matcher.match('foo'   )).to be_truthy
          expect(matcher.match('foobar')).to be_falsey
          expect(matcher.match('bazfoo')).to be_falsey
        end
      end

      context 'falseが設定された場合' do
        let(:matcher) { create_matcher(/foo/, match_wholly: false) }

        it '与えられたパターンを入力の一部に対するパターンとして、マッチングを行う' do
          expect(matcher.match('foo'   )).to be_truthy
          expect(matcher.match('foobar')).to be_truthy
          expect(matcher.match('bazfoo')).to be_truthy
        end
      end

      context '未指定の場合' do
        let(:matcher) { create_matcher(/foo/) }

        it 'trueが設定された場合と同じマッチングを行う' do
          expect(matcher.match('foo'   )).to be_truthy
          expect(matcher.match('foobar')).to be_falsey
          expect(matcher.match('bazfoo')).to be_falsey
        end
      end
    end

    describe 'ignore_blanksオプション' do
      let(:inputs) do
        ['foo-bar baz _qux', 'foo-bar  baz   _qux', " foo -\tbar baz\t_qux\t", " foo -\nbar baz\n_qux"]
      end

      context 'trueが設定された場合' do
        let(:matcher) { create_matcher(/foo-bar baz _qux/, ignore_blanks: true) }

        it '単語間の空白を圧縮し、改行を除く空白を無視して、一致比較を行う' do
          expect(matcher.match(inputs[0])).to be_truthy
          expect(matcher.match(inputs[1])).to be_truthy
          expect(matcher.match(inputs[2])).to be_truthy
          expect(matcher.match(inputs[3])).to be_falsey
        end
      end

      context 'falseが設定された場合' do
        let(:matcher) { create_matcher(/foo-bar baz _qux/, ignore_blanks: false) }

        it '空白の無視はせず、一致比較を行う' do
          expect(matcher.match(inputs[0])).to be_truthy
          expect(matcher.match(inputs[1])).to be_falsey
          expect(matcher.match(inputs[2])).to be_falsey
          expect(matcher.match(inputs[3])).to be_falsey
        end
      end

      context '無指定の場合' do
        let(:matcher) { create_matcher(/foo-bar baz _qux/) }

        it 'trueが設定された場合と同じマッチングを行う' do
          expect(matcher.match(inputs[0])).to be_truthy
          expect(matcher.match(inputs[1])).to be_truthy
          expect(matcher.match(inputs[2])).to be_truthy
          expect(matcher.match(inputs[3])).to be_falsey
        end
      end
    end
  end
end

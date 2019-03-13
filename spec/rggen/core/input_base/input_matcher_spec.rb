# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::InputBase
  describe InputMatcher do
    def create_matcher(pattern, options = {}, &conveter)
      InputMatcher.new(pattern, options, &conveter)
    end

    describe "#match" do
      it "指定された入力と、生成時に与えられた正規表現とでマッチングを行う" do
        expect(create_matcher(/foo/).match('foo')).to be_truthy
        expect(create_matcher(/foo/).match(:foo )).to be_truthy
        expect(create_matcher(/foo/).match('bar')).to be_falsey
        expect(create_matcher(/1/  ).match(1    )).to be_falsey
      end

      context "入力がマッチした場合" do
        it "MatchDataを返す" do
          expect(create_matcher(/foo/).match('foo')).to be_instance_of(MatchData)
        end
      end

      context "入力がマッチし、生成時にブロックが与えられている場合" do
        specify "ブロックは MatchDataを受け取る" do
          expect { |b|
            create_matcher(/foo/, &b).match('foo')
          }.to yield_with_args(MatchData)
        end

        it "ブロックの評価結果を返す" do
          expect(
            create_matcher(/(foo)(bar)/) { |m| m.captures.map(&:upcase) }.match('foobar')
          ).to match ['FOO', 'BAR']
        end
      end

      describe "match_whollyオプション" do
        context "trueが設定された場合" do
          let(:matcher) { create_matcher(/foo/, match_wholly: true) }

          it "与えられたパターンを入力の全体に対するパターンとして、マッチングを行う" do
            expect(matcher.match('foo'   )).to be_truthy
            expect(matcher.match('foobar')).to be_falsey
            expect(matcher.match('bazfoo')).to be_falsey
          end
        end

        context "falseが設定された場合" do
          let(:matcher) { create_matcher(/foo/, match_wholly: false) }

          it "与えられたパターンを入力の一部に対するパターンとして、マッチングを行う" do
            expect(matcher.match('foo'   )).to be_truthy
            expect(matcher.match('foobar')).to be_truthy
            expect(matcher.match('bazfoo')).to be_truthy
          end
        end

        context "未指定の場合" do
          let(:matcher) { create_matcher(/foo/) }

          it "trueが設定された場合と同じマッチングを行う" do
            expect(matcher.match('foo'   )).to be_truthy
            expect(matcher.match('foobar')).to be_falsey
            expect(matcher.match('bazfoo')).to be_falsey
          end
        end
      end

      describe "convert_to_stringオプション" do
        context "trueが設定された場合" do
          let(:matcher) { create_matcher(/1/, convert_to_string: true) }

           it "入力を文字列に変換した上で、マッチングを行う" do
            expect(matcher.match('1')).to be_truthy
            expect(matcher.match( 1 )).to be_truthy
          end
        end

        context "trueが設定された場合" do
          let(:matcher) { create_matcher(/1/, convert_to_string: false) }

          it "入力を文字列に変換せず、そのままマッチングを行う" do
            expect(matcher.match('1')).to be_truthy
            expect(matcher.match( 1 )).to be_falsey
          end
        end

        context "未指定の場合" do
          let(:matcher) { create_matcher(/1/, convert_to_string: false) }

          it "falseが設定された場合と同じマッチングを行う" do
            expect(matcher.match('1')).to be_truthy
            expect(matcher.match( 1 )).to be_falsey
          end
        end
      end

      describe "ignore_blanksオプション" do
        let(:inputs) do
          ['foo-bar baz', 'foo-bar  baz', " foo -\tbar baz\t", " foo -\nbar baz\t"]
        end

        context "trueが設定された場合" do
          let(:matcher) { create_matcher(/foo-bar baz/, ignore_blanks: true) }

          it "単語間の空白を圧縮し、改行を除く空白を無視して、一致比較を行う" do
            expect(matcher.match(inputs[0])).to be_truthy
            expect(matcher.match(inputs[1])).to be_truthy
            expect(matcher.match(inputs[2])).to be_truthy
            expect(matcher.match(inputs[3])).to be_falsey
          end
        end

        context "falseが設定された場合" do
          let(:matcher) { create_matcher(/foo-bar baz/, ignore_blanks: false) }

          it "空白の無視はせず、一致比較を行う" do
            expect(matcher.match(inputs[0])).to be_truthy
            expect(matcher.match(inputs[1])).to be_falsey
            expect(matcher.match(inputs[2])).to be_falsey
            expect(matcher.match(inputs[3])).to be_falsey
          end
        end

        context "無指定の場合" do
          let(:matcher) { create_matcher(/foo-bar baz/) }

          it "trueが設定された場合と同じマッチングを行う" do
            expect(matcher.match(inputs[0])).to be_truthy
            expect(matcher.match(inputs[1])).to be_truthy
            expect(matcher.match(inputs[2])).to be_truthy
            expect(matcher.match(inputs[3])).to be_falsey
          end
        end
      end
    end
  end
end

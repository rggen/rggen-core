# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::InputBase
  describe Feature do
    def define_feature(base = Feature, &body)
      Class.new(base, &body)
    end

    def create_feature(base = Feature, &body)
      define_feature(base, &body).new(RgGen::Core::Base::Component.new, :feature)
    end

    def create_input_value(value, position = nil)
      InputValue.new(value, position)
    end

    describe ".property" do
      it "プロパティを定義する" do
        expect(define_feature { property :foo }).to have_property :foo
      end

      specify "定義済みのプロパティは.propertiesで参照できる" do
        feature = define_feature { property :foo; property :bar }
        expect(feature.properties).to match [:foo, :bar]
      end

      specify "定義したプロパティは継承される" do
        parent = define_feature { property :foo; property :bar }
        feature = define_feature(parent) { property :baz }
        expect(feature.properties).to match [:foo, :bar, :baz]
      end

      context "同名のプロパティを複数定義した場合" do
        let(:feature) do
          create_feature do
            property(:foo) { foo_0 }
            property(:foo) { foo_1 }
          end
        end

        it "後の定義を優先する" do
          expect(feature).not_to receive(:foo_0)
          expect(feature).to receive(:foo_1)
          feature.foo
        end

        specify ".propertiesへの追加は1度だけ行う" do
          expect(feature.properties).to match [:foo]
        end
      end

      specify ".fieldでもプロパティを定義できる" do
        feature = define_feature do
          field :foo
          field :bar
        end
        expect(feature.properties).to match [:foo, :bar]
      end
    end

    describe '.ignore_empty_value' do
      it '空入力を無視するかどうかを示す' do
        feature = create_feature { ignore_empty_value true }
        expect(feature.ignore_empty_value?).to be_truthy

        feature = create_feature { ignore_empty_value false }
        expect(feature.ignore_empty_value?).to be_falsey
      end

      specify 'デフォルトは空入力を無視' do
        feature = create_feature
        expect(feature.ignore_empty_value?).to be_truthy
      end

      specify '設定は継承される' do
        feature = create_feature(define_feature { ignore_empty_value true })
        expect(feature.ignore_empty_value?).to be_truthy

        feature = create_feature(define_feature { ignore_empty_value false })
        expect(feature.ignore_empty_value?).to be_falsey
      end
    end

    describe "#build" do
      let(:feature) do
        create_feature do
          build { |*args| foo(*args) }
        end
      end

      let(:child_feature) do
        create_feature(feature.class) do
          build { |*args| bar(*args) }
        end
      end

      let(:grandchild_feature) do
        create_feature(child_feature.class)
      end

      let(:value) { Object.new }

      let(:position) { Struct.new(:x, :y).new(0, 1) }

      let(:input_value) { create_input_value(value, position) }

      let(:other_value) { Object.new }

      let(:other_position) { Struct.new(:a, :b).new(2, 3) }

      let(:other_input_value) { create_input_value(other_value, other_position) }

      it ".buildで登録されたブロックを実行し、フィーチャーの組み立てを行う" do
        expect(feature).to receive(:foo)
        feature.build(input_value)
      end

      specify "入力データの#valueが組み立てブロックに渡される" do
        expect(feature).to receive(:foo).with(equal(value))
        feature.build(input_value)
      end

      specify "入力データの#positionは、フィーチャー内に#positionとして保持される" do
        allow(feature).to receive(:foo)
        feature.build(input_value)
        expect(feature.send(:position)).to eq position
      end

      specify "#value/#positionの取り出しは、末尾の入力値に対して行われる" do
        expect(feature).to receive(:foo).with(equal(other_input_value), equal(value))
        feature.build(other_input_value, input_value)
        expect(feature.send(:position)).to eq position
      end

      specify "登録された組み立てブロックは、継承される" do
        expect(grandchild_feature).to receive(:foo).with(equal(value))
        expect(grandchild_feature).to receive(:bar).with(equal(value))
        grandchild_feature.build(input_value)
      end

      it "組み立てブロックの登録がなくても、実行できる" do
        expect {
          create_feature.build(input_value)
        }.not_to raise_error
      end

      specify "組みてたブロックの登録があるフィーチャーを能動フィーチャーとする" do
        feature = create_feature { build {} }
        expect(feature).to be_active_feature
        expect(feature.class).to be_active_feature
        expect(feature).not_to be_passive_feature
        expect(feature.class).not_to be_passive_feature
      end

      specify "組みてたブロックの登録がないフィーチャーを受動フィーチャーとする" do
        feature = create_feature
        expect(feature).not_to be_active_feature
        expect(feature.class).not_to be_active_feature
        expect(feature).to be_passive_feature
        expect(feature.class).to be_passive_feature
      end
    end

    describe "#match_pattern" do
      it ".input_patternで登録されたパターンで、一致比較を行う" do
        feature = create_feature { input_pattern %r{foo} }
        expect(feature.send(:match_pattern, 'foo')).to be_instance_of(MatchData)
        expect(feature.send(:match_pattern, 'bar')).to be_falsey
      end

      it "InputMatcher#matchを用いて、一致比較を行う" do
        feature = create_feature { input_pattern %r{foo} }
        expect_any_instance_of(InputMatcher).to receive(:match)
        feature.send(:match_pattern, 'foo')
      end

      specify "パターン登録時に、InputMatcherに対して、オプションやブロックを渡すことができる" do
        feature = create_feature do
          input_pattern(/(foo)(bar)/, match_wholly: false) { |m| m.captures.map(&:upcase) }
        end
        expect(feature.send(:match_pattern, ' foobar ')).to match ['FOO', 'BAR']
      end

      describe "#match_data" do
        let(:foo_feature) { create_feature { input_pattern(%r{foo}) } }
        let(:bar_feature) { create_feature { input_pattern(%r{bar}) { |m| m[0].upcase } }}

        it "直近の比較結果を返す" do
          foo_feature.send(:match_pattern, 'foo')
          bar_feature.send(:match_pattern, 'bar')
          expect(foo_feature.send(:match_data)[0]).to eq 'foo'
          expect(bar_feature.send(:match_data)).to eq 'BAR'

          foo_feature.send(:match_pattern, 'baz')
          bar_feature.send(:match_pattern, 'baz')
          expect(foo_feature.send(:match_data)).to be_nil
          expect(bar_feature.send(:match_data)).to be_nil
        end
      end

      describe "pattern_matched?" do
        let(:feature) { create_feature { input_pattern %r{foo} } }

        it "直近の比較が成功したかどうかを返す" do
          feature.send(:match_pattern, 'foo')
          expect(feature.send(:pattern_matched?)).to be true
          feature.send(:match_pattern, 'bar')
          expect(feature.send(:pattern_matched?)).to be false
        end
      end

      describe "match_automaticallyオプション" do
        let(:input_values) { [:foo, :bar].map { |value| create_input_value(value) } }

        context "trueが設定された場合" do
          let(:feature) do
            create_feature do
              input_pattern %r{foo}, match_automatically: true
              build {}
            end
          end

          it "#build実行時に、自動で末尾の引数に対して一致比較を行う" do
            expect(feature).to receive(:match_pattern).with(:bar)
            feature.build(*input_values)
          end
        end

        context "falseが設定された場合" do
          let(:feature) do
            create_feature do
              input_pattern %r{foo}, match_automatically: false
              build {}
            end
          end

          it "#build実行時に、自動で一致比較を行わない" do
            expect(feature).not_to receive(:match_pattern)
            feature.build(*input_values)
          end
        end

        context "設定がない場合" do
          let(:feature) do
            create_feature do
              input_pattern %r{foo}
              build {}
            end
          end

          it "#build実行時に、自動で一致比較を行う" do
            expect(feature).to receive(:match_pattern)
            feature.build(*input_values)
          end
        end
      end

      specify "パターンは継承される" do
        feature = create_feature(define_feature {
          input_pattern %r{foo}
          build {}
        })
        feature.build(create_input_value(:foo))
        expect(feature.send(:pattern_matched?)).to be true
      end
    end

    describe '#verify' do
      let(:feature) do
        create_feature do
          verify(:feature) { foo_0 }
          verify(:component) { bar_0 }
          verify(:all) { baz_0 }
        end
      end

      let(:child_feature) do
        create_feature(feature.class) do
          verify(:feature) { foo_1 }
          verify(:component) { bar_1 }
          verify(:all) { baz_1 }
        end
      end

      let(:grandchild_feature) do
        create_feature(child_feature.class)
      end

      context '検証範囲が:featureの場合' do
        it '.verify(:feature)で登録された検証ブロックを実行し、フィーチャーの検証を行う' do
          expect(feature).to receive(:foo_0)
          feature.verify(:feature)
        end
      end

      context '検証範囲が:componentの場合' do
        it '.verify(:component)で登録された検証ブロックを実行し、コンポーネントの検証を行う' do
          expect(feature).to receive(:bar_0)
          feature.verify(:component)
        end
      end

      context '検証範囲が:allの場合' do
        it '.verify(:all)で登録された検証ブロックを実行し、全体の検証を行う' do
          expect(feature).to receive(:baz_0)
          feature.verify(:all)
        end
      end

      specify '検証は一度だけ行われる' do
        expect(feature).to receive(:foo_0).once
        expect(feature).to receive(:bar_0).once
        expect(feature).to receive(:baz_0).once

        2.times do
          feature.verify(:feature)
          feature.verify(:component)
          feature.verify(:all)
        end
      end

      specify '登録された検証ブロックは継承される' do
        expect(grandchild_feature).to receive(:foo_0)
        expect(grandchild_feature).to receive(:foo_1)
        grandchild_feature.verify(:feature)

        expect(grandchild_feature).to receive(:bar_0)
        expect(grandchild_feature).to receive(:bar_1)
        grandchild_feature.verify(:component)

        expect(grandchild_feature).to receive(:baz_0)
        expect(grandchild_feature).to receive(:baz_1)
        grandchild_feature.verify(:all)
      end

      it '検証ブロックの登録がなくても、エラー無く、実行できる' do
        expect {
          create_feature.verify(:feature)
        }.not_to raise_error

        expect {
          create_feature.verify(:component)
        }.not_to raise_error

        expect {
          create_feature.verify(:all)
        }.not_to raise_error
      end
    end
  end
end

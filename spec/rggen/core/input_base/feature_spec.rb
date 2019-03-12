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

      context "プロパティ名のみが与えられた場合" do
        let(:feature) do
          create_feature do
            property :foo
            def initialize(component, feature_name)
              super
              @foo = 1
            end
          end
        end

        it "同名のインスタンス変数を返すプロパティを定義する" do
          expect(feature).to have_property :foo, 1
        end
      end

      context "?付きプロパティ名が与えられた場合" do
        let(:feature) do
          create_feature do
            property :foo?
            def initialize(component, feature_name)
              super
              @foo = true
            end
          end
        end

        it "?を除いた同名のインスタンス変数を返すプロパティを定義する" do
          expect(feature).to have_property :foo?, true
        end
      end

      context "ブロックが与えられた場合" do
        let(:feature) do
          create_feature do
            property(:foo) { baz }
            property(:bar) { |v| v }
            private
            def baz; 1 end
          end
        end

        it "ブロックを自身のコンテキストで実行するプロパティを定義する" do
          expect(feature).to have_property :foo, 1
        end

        specify "定義されたプロパティは引数を取ることができる" do
          expect(feature.bar(2)).to eq 2
        end
      end

      describe "defaultオプション" do
        let(:feature) do
          create_feature do
            property :foo, default: 1
            property :bar, default: 2
            def initialize(component, feature_name)
              super
              @bar = 3
            end
          end
        end

        it "プロパティのデフォルト値を設定する" do
          expect(feature).to have_property :foo, 1
          expect(feature).to have_property :bar, 3
        end
      end

      describe "forward_to_helperオプション" do
        context "trueが設定された場合" do
          let(:feature) do
            create_feature do
              property :foo, forward_to_helper: true
              property :bar, forward_to_helper: true
              define_helpers do
                def foo; 1 end
                def bar(v)
                  return v unless block_given?
                  yield(v)
                end
              end
            end
          end

          it "ヘルパーメソッドに委譲するプロパティを定義する" do
            expect(feature.class).to receive(:foo).and_call_original
            expect(feature).to have_property :foo, 1
          end

          specify "定義するプロパティは引数およびブロックを取ることができる" do
            expect(feature.bar(1)).to eq 1
            expect(feature.bar(2) { |v| 2 * v} ).to eq 4
          end
        end

        context "falseが設定された場合" do
          let(:feature) do
            create_feature do
              property :foo, forward_to_helper: false
              define_helpers { def foo; 1 end }
              def initialize(component, feature_name)
                super
                @foo = 2
              end
            end
          end

          before do
            expect(feature.class).not_to receive(:foo)
          end

          it "通常のプロパティを定義する" do
            expect(feature).to have_property :foo, 2
          end
        end
      end

      describe "forward_toオプション" do
        let(:feature) do
          create_feature do
            property :foo, forward_to: :bar
            property :baz, forward_to: :qux
            def bar; 1 end
            def qux(v)
              return v unless block_given?
              yield(v)
            end
          end
        end

        it "指定したメソッドに移譲するプロパティを定義する" do
          expect(feature).to receive(:bar).and_call_original
          expect(feature).to have_property :foo, 1
        end

        specify "定義するプロパティは引数およびブロックを取ることができる" do
          expect(feature.baz(2)).to eq 2
          expect(feature.baz(2) { |v| 2 * v}).to eq 4
        end
      end

      describe "need_validationオプション" do
        context "trueが設定された場合" do
          let(:feature) do
            create_feature { property :foo, need_validation: true }
          end

          specify "プロパティ呼び出し時に、#validateを呼び出して、検査を実施する" do
            expect(feature).to receive(:validate)
            feature.foo
          end
        end

        context "falseが設定された場合" do
          let(:feature) do
            create_feature { property :foo, need_validation: false }
          end

          specify "プロパティ呼び出し時に、検査を実施しない" do
            expect(feature).not_to receive(:validate)
            feature.foo
          end
        end

        context "指定がない場合" do
          let(:feature) do
            create_feature  { property :foo }
          end

          specify "プロパティ呼び出し時に、検査を実施しない" do
            expect(feature).not_to receive(:validate)
            feature.foo
          end
        end
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

    describe "#validate" do
      let(:feature) do
        create_feature do
          validate { foo }
        end
      end

      let(:child_feature) do
        create_feature(feature.class) do
          validate { bar }
        end
      end

      let(:grandchild_feature) do
        create_feature(child_feature.class)
      end

      it ".validateで登録されたブロックを実行し、フィーチャーの検査をおこなう" do
        expect(feature).to receive(:foo)
        feature.validate
      end

      it "検査ブロックは一度しか実行しない" do
        expect(feature).to receive(:foo).once
        2.times { feature.validate }
      end

      specify "登録された検査ブロックは、継承される" do
        expect(grandchild_feature).to receive(:foo)
        expect(grandchild_feature).to receive(:bar)
        grandchild_feature.validate
      end

      it "検査ブロックの登録がなくても、実行できる" do
        expect {
          create_feature.validate
        }.not_to raise_error
      end
    end

    describe "#pattern_match" do
      it ".input_patternで登録されたパターンで、一致比較を行う" do
        feature = create_feature { input_pattern %r{foo} }
        expect(feature.send(:pattern_match, 'foo')).to be_instance_of(MatchData)
        expect(feature.send(:pattern_match, 'bar')).to be_falsey
      end

      it "InputMatcher::matchを用いて、一致比較を行う" do
        feature = create_feature { input_pattern %r{foo} }
        expect_any_instance_of(InputMatcher).to receive(:match)
        feature.send(:pattern_match, 'foo')
      end

      specify "パターン登録時に、InputMatcherに対して、オプションやブロックを渡すことができる" do
        feature = create_feature do
          input_pattern(/(foo)(bar)/, convert_string: true) { |m| m.captures.map(&:upcase) }
        end
        expect(feature.send(:pattern_match, :foobar)).to match ['FOO', 'BAR']
      end

      describe "#match_data" do
        let(:foo_feature) { create_feature { input_pattern(%r{foo}) } }
        let(:bar_feature) { create_feature { input_pattern(%r{bar}) { |m| m[0].upcase } }}

        it "直近の比較結果を返す" do
          foo_feature.send(:pattern_match, 'foo')
          bar_feature.send(:pattern_match, 'bar')
          expect(foo_feature.send(:match_data)[0]).to eq 'foo'
          expect(bar_feature.send(:match_data)).to eq 'BAR'

          foo_feature.send(:pattern_match, 'baz')
          bar_feature.send(:pattern_match, 'baz')
          expect(foo_feature.send(:match_data)).to be_nil
          expect(bar_feature.send(:match_data)).to be_nil
        end
      end

      describe "pattern_matched?" do
        let(:feature) { create_feature { input_pattern %r{foo} } }

        it "直近の比較が成功したかどうかを返す" do
          feature.send(:pattern_match, 'foo')
          expect(feature.send(:pattern_matched?)).to be true
          feature.send(:pattern_match, 'bar')
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
            expect(feature).to receive(:pattern_match).with(:bar)
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
            expect(feature).not_to receive(:pattern_match)
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

          it "#build実行時に、自動で一致比較を行わない" do
            expect(feature).not_to receive(:pattern_match)
            feature.build(*input_values)
          end
        end
      end

      specify "パターン及びmatch_automaticallyオプションは継承される" do
        feature = create_feature(define_feature {
          input_pattern %r{foo}, match_automatically: true
          build {}
        })
        feature.build(create_input_value(:foo))
        expect(feature.send(:pattern_matched?)).to be true
      end
    end
  end
end

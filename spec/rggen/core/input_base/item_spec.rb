require 'spec_helper'

module RgGen::Core::InputBase
  describe Item do
    def define_item(base = Item, &body)
      Class.new(base, &body)
    end

    def create_item(base = Item, &body)
      define_item(base, &body).new(RgGen::Core::Base::Component.new, :item)
    end

    def create_input_value(value, position = nil)
      InputValue.new(value, position)
    end

    describe ".field" do
      matcher :have_field do |field_name, *field_value|
        match do |item|
          case item
          when Class
            @field_defined = item.method_defined?(field_name)
            @match_value = true
          when Item
            @field_defined = item.public_methods(false).include?(field_name)
            @match_value = field_value.empty? || (@field_defined && values_match?(field_value[0], actual_field_value))
          end
          @field_defined && @match_value
        end

        failure_message do
          if !@field_defined
            "no such field defined: #{field_name}"
          elsif !@match_value
            "expected #{field_value[0].inspect} as field value but got #{actual_field_value.inspect}"
          end
        end

        define_method(:actual_field_value) do
          @actual_field_value ||= item.__send__(field_name)
        end
      end

      it "フィールドを定義する" do
        expect(define_item { field :foo }).to have_field :foo
      end

      specify "定義済みのフィールドは.fieldsで参照できる" do
        expect(define_item { field :foo; field :bar }.fields).to match [:foo, :bar]
      end

      specify "定義したフィールドは継承される" do
        parent = define_item { field :foo; field :bar }
        expect(define_item(parent) { field :baz }.fields).to match [:foo, :bar, :baz]
      end

      context "フィールド名のみが与えられた場合" do
        let(:item) do
          create_item do
            field :foo
            def initialize(component, item_name)
              super
              @foo = 1
            end
          end
        end

        it "同名のインスタンス変数を返すフィールドを定義する" do
          expect(item).to have_field :foo, 1
        end
      end

      context "?付きフィールド名が与えられた場合" do
        let(:item) do
          create_item do
            field :foo?
            def initialize(component, item_name)
              super
              @foo = true
            end
          end
        end

        it "?を除いた同名のインスタンス変数を返すフィールドを定義する" do
          expect(item).to have_field :foo?, true
        end
      end

      context "ブロックが与えられた場合" do
        let(:item) do
          create_item do
            field(:foo) { baz }
            field(:bar) { |v| v }
            private
            def baz; 1 end
          end
        end

        it "ブロックを自身のコンテキストで実行するフィールドを定義する" do
          expect(item).to have_field :foo, 1
        end

        specify "定義されたフィールドは引数を取ることができる" do
          expect(item.bar(2)).to eq 2
        end
      end

      describe "defaultオプション" do
        let(:item) do
          create_item do
            field :foo, default: 1
            field :bar, default: 2
            def initialize(component, item_name)
              super
              @bar = 3
            end
          end
        end

        it "フィールドのデフォルト値を設定する" do
          expect(item).to have_field :foo, 1
          expect(item).to have_field :bar, 3
        end
      end

      describe "forward_to_helperオプション" do
        context "trueが設定された場合" do
          let(:item) do
            create_item do
              field :foo, forward_to_helper: true
              field :bar, forward_to_helper: true
              define_helpers do
                def foo; 1 end
                def bar(v)
                  return v unless block_given?
                  yield(v)
                end
              end
            end
          end

          it "ヘルパーメソッドに委譲するフィールドを定義する" do
            expect(item.class).to receive(:foo).and_call_original
            expect(item).to have_field :foo, 1
          end

          specify "定義するフィールドは引数およびブロックを取ることができる" do
            expect(item.bar(1)).to eq 1
            expect(item.bar(2) { |v| 2 * v} ).to eq 4
          end
        end

        context "falseが設定された場合" do
          let(:item) do
            create_item do
              field :foo, forward_to_helper: false
              define_helpers { def foo; 1 end }
              def initialize(component, item_name)
                super
                @foo = 2
              end
            end
          end

          before do
            expect(item.class).not_to receive(:foo)
          end

          it "通常のフィールドを定義する" do
            expect(item).to have_field :foo, 2
          end
        end
      end

      describe "forward_toオプション" do
        let(:item) do
          create_item do
            field :foo, forward_to: :bar
            field :baz, forward_to: :qux
            def bar; 1 end
            def qux(v)
              return v unless block_given?
              yield(v)
            end
          end
        end

        it "指定したメソッドに移譲するフィールドを定義する" do
          expect(item).to receive(:bar).and_call_original
          expect(item).to have_field :foo, 1
        end

        specify "定義するフィールドは引数およびブロックを取ることができる" do
          expect(item.baz(2)).to eq 2
          expect(item.baz(2) { |v| 2 * v}).to eq 4
        end
      end

      describe "need_validationオプション" do
        context "trueが設定された場合" do
          let(:item) do
            create_item { field :foo, need_validation: true }
          end

          specify "フィールド呼び出し時に、#validateを呼び出して、検査を実施する" do
            expect(item).to receive(:validate)
            item.foo
          end
        end

        context "falseが設定された場合" do
          let(:item) do
            create_item { field :foo, need_validation: false }
          end

          specify "フィールド呼び出し時に、検査を実施しない" do
            expect(item).not_to receive(:validate)
            item.foo
          end
        end

        context "指定がない場合" do
          let(:item) do
            create_item  { field :foo }
          end

          specify "フィールド呼び出し時に、検査を実施しない" do
            expect(item).not_to receive(:validate)
            item.foo
          end
        end
      end

      context "同名のフィールドを複数定義した場合" do
        let(:item) do
          create_item do
            field(:foo) { foo_0 }
            field(:foo) { foo_1 }
          end
        end

        it "後の定義を優先する" do
          expect(item).not_to receive(:foo_0)
          expect(item).to receive(:foo_1)
          item.foo
        end

        specify ".fieldsへの追加は1度だけ行う" do
          expect(item.fields).to match [:foo]
        end
      end
    end

    describe "#build" do
      let(:item) do
        create_item do
          build { |*args| foo(*args) }
        end
      end

      let(:child_item) do
        create_item(item.class) do
          build { |*args| bar(*args) }
        end
      end

      let(:grandchild_item) do
        create_item(child_item.class)
      end

      let(:value) { Object.new }

      let(:position) { Struct.new(:x, :y).new(0, 1) }

      let(:input_value) { create_input_value(value, position) }

      let(:other_value) { Object.new }

      let(:other_position) { Struct.new(:a, :b).new(2, 3) }

      let(:other_input_value) { create_input_value(other_value, other_position) }

      it ".buildで登録されたブロックを実行し、アイテムの組み立てを行う" do
        expect(item).to receive(:foo)
        item.build(input_value)
      end

      specify "入力データの#valueが組み立てブロックに渡される" do
        expect(item).to receive(:foo).with(equal(value))
        item.build(input_value)
      end

      specify "入力データの#positionは、アイテム内に#positionとして保持される" do
        allow(item).to receive(:foo)
        item.build(input_value)
        expect(item.send(:position)).to eq position
      end

      specify "#value/#positionの取り出しは、末尾の入力値に対して行われる" do
        expect(item).to receive(:foo).with(equal(other_input_value), equal(value))
        item.build(other_input_value, input_value)
        expect(item.send(:position)).to eq position
      end

      specify "登録された組み立てブロックは、継承される" do
        expect(grandchild_item).to receive(:foo).with(equal(value))
        expect(grandchild_item).to receive(:bar).with(equal(value))
        grandchild_item.build(input_value)
      end

      it "組み立てブロックの登録がなくても、実行できる" do
        expect {
          create_item.build(input_value)
        }.not_to raise_error
      end

      specify "組みてたブロックの登録があるアイテムを能動アイテムとする" do
        item = create_item { build {} }
        expect(item).to be_active_item
        expect(item.class).to be_active_item
        expect(item).not_to be_passive_item
        expect(item.class).not_to be_passive_item
      end

      specify "組みてたブロックの登録がないアイテムを受動アイテムとする" do
        item = create_item
        expect(item).not_to be_active_item
        expect(item.class).not_to be_active_item
        expect(item).to be_passive_item
        expect(item.class).to be_passive_item
      end
    end

    describe "#validate" do
      let(:item) do
        create_item do
          validate { foo }
        end
      end

      let(:child_item) do
        create_item(item.class) do
          validate { bar }
        end
      end

      let(:grandchild_item) do
        create_item(child_item.class)
      end

      it ".validateで登録されたブロックを実行し、アイテムの検査をおこなう" do
        expect(item).to receive(:foo)
        item.validate
      end

      it "検査ブロックは一度しか実行しない" do
        expect(item).to receive(:foo).once
        2.times { item.validate }
      end

      specify "登録された検査ブロックは、継承される" do
        expect(grandchild_item).to receive(:foo)
        expect(grandchild_item).to receive(:bar)
        grandchild_item.validate
      end

      it "検査ブロックの登録がなくても、実行できる" do
        expect {
          create_item.validate
        }.not_to raise_error
      end
    end

    describe "#pattern_match" do
      it ".input_patternで登録されたパターンで、一致比較を行う" do
        item = create_item { input_pattern %r{foo} }
        expect(item.send(:pattern_match, 'foo')).to be_instance_of(MatchData)
        expect(item.send(:pattern_match, 'bar')).to be_falsey
      end

      it "InputMatcher::matchを用いて、一致比較を行う" do
        item = create_item { input_pattern %r{foo} }
        expect_any_instance_of(InputMatcher).to receive(:match)
        item.send(:pattern_match, 'foo')
      end

      specify "パターン登録時に、InputMatcherに対して、オプションやブロックを渡すことができる" do
        item = create_item do
          input_pattern(/(foo)(bar)/, convert_string: true) { |m| m.captures.map(&:upcase) }
        end
        expect(item.send(:pattern_match, :foobar)).to match ['FOO', 'BAR']
      end

      describe "#match_data" do
        let(:foo_item) { create_item { input_pattern(%r{foo}) } }
        let(:bar_item) { create_item { input_pattern(%r{bar}) { |m| m[0].upcase } }}

        it "直近の比較結果を返す" do
          foo_item.send(:pattern_match, 'foo')
          bar_item.send(:pattern_match, 'bar')
          expect(foo_item.send(:match_data)[0]).to eq 'foo'
          expect(bar_item.send(:match_data)).to eq 'BAR'

          foo_item.send(:pattern_match, 'baz')
          bar_item.send(:pattern_match, 'baz')
          expect(foo_item.send(:match_data)).to be_nil
          expect(bar_item.send(:match_data)).to be_nil
        end
      end

      describe "pattern_matched?" do
        let(:item) { create_item { input_pattern %r{foo} } }

        it "直近の比較が成功したかどうかを返す" do
          item.send(:pattern_match, 'foo')
          expect(item.send(:pattern_matched?)).to be true
          item.send(:pattern_match, 'bar')
          expect(item.send(:pattern_matched?)).to be false
        end
      end

      describe "match_automaticallyオプション" do
        let(:input_values) { [:foo, :bar].map { |value| create_input_value(value) } }

        context "trueが設定された場合" do
          let(:item) do
            create_item do
              input_pattern %r{foo}, match_automatically: true
              build {}
            end
          end

          it "#build実行時に、自動で末尾の引数に対して一致比較を行う" do
            expect(item).to receive(:pattern_match).with(:bar)
            item.build(*input_values)
          end
        end

        context "falseが設定された場合" do
          let(:item) do
            create_item do
              input_pattern %r{foo}, match_automatically: false
              build {}
            end
          end

          it "#build実行時に、自動で一致比較を行わない" do
            expect(item).not_to receive(:pattern_match)
            item.build(*input_values)
          end
        end

        context "設定がない場合" do
          let(:item) do
            create_item do
              input_pattern %r{foo}
              build {}
            end
          end

          it "#build実行時に、自動で一致比較を行わない" do
            expect(item).not_to receive(:pattern_match)
            item.build(*input_values)
          end
        end
      end

      specify "パターン及びmatch_automaticallyオプションは継承される" do
        item = create_item(define_item {
          input_pattern %r{foo}, match_automatically: true
          build {}
        })
        item.build(create_input_value(:foo))
        expect(item.send(:pattern_matched?)).to be true
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::Property do
  describe '.define' do
    def create_feature(&body)
      Class.new(&body).new
    end

    def define_property(feature, name, **options, &body)
      described_class.define(feature.class, name, **options, &body)
    end

    context 'プロパティ名のみ与えられた場合' do
      let(:feature) do
        create_feature do
          def initialize; @foo = 1; end
        end
      end

      it '同名のフィーチャー上のインスタンス変数を返すプロパティを定義する' do
        define_property(feature, :foo)
        expect(feature.foo).to eq 1
      end
    end

    context '末尾に ? が付くプロパティ名が与えられた場合' do
      let(:feature) do
        create_feature do
          def initialize; @foo = 1; end
        end
      end

      it '同名(?は除く)のフィーチャー上のインスタンス変数を返すプロパティを定義する' do
        define_property(feature, :foo?)
        expect(feature.foo?).to eq 1
      end
    end

    context 'ブロックが与えられた場合' do
      let(:feature) do
        create_feature do
          def initialize; @foo = 1; end
          def bar; 2; end
        end
      end

      it 'ブロックをフィーチャ上で実行するプロパティを定義する' do
        define_property(feature, :foo) { @foo }
        expect(feature.foo).to eq 1

        define_property(feature, :barbar) { 2 * bar }
        expect(feature.barbar).to eq 4
      end

      specify '定義されたプロパティは引数、ブロックを取れる' do
        define_property(feature, :foo) { |v, &b| v + b.call }
        expect(feature.foo(2) { 3 }).to eq 5
      end
    end

    describe 'bodyオプション' do
      let(:feature) do
        create_feature do
          def initialize; @foo = 1; end
          def bar; 2; end
        end
      end

      it 'ブロックをフィーチャ上で実行するプロパティを定義する' do
        define_property(feature, :foo, body: -> { @foo })
        expect(feature.foo).to eq 1

        define_property(feature, :barbar, body: ->  { 2 * bar })
        expect(feature.barbar).to eq 4
      end

      specify '定義されたプロパティは引数、ブロックを取れる' do
        define_property(feature, :foo, body: ->(v, &b) { v + b.call })
        expect(feature.foo(2) { 3 }).to eq 5
      end
    end

    describe 'defaultオプション' do
      let(:feature) do
        create_feature do
          def set_foo; @foo = 1; end
          def set_bar; @bar = true; end
          def default_foo_value; 2; end
          def default_bar_value; false; end
        end
      end

      context 'ブロックを与えた場合' do
        it 'ブロックの評価結果を、プロパティの既定値とする' do
          define_property(feature, :foo, default: -> { default_foo_value } )
          define_property(feature, :bar?, default: -> { default_bar_value } )

          expect(feature.foo).to eq 2
          expect(feature.bar?).to eq false
          expect(feature.instance_variables).not_to include(:@foo)
          expect(feature.instance_variables).not_to include(:@bar)

          feature.set_foo
          feature.set_bar
          expect(feature.foo).to eq 1
          expect(feature.bar?).to eq true
        end
      end

      context 'ブロック以外を与えた場合' do
        it '指定された値を、プロパティの既定値とする' do
          define_property(feature, :foo, default: 0)
          define_property(feature, :bar?, default: false)

          expect(feature.foo).to eq 0
          expect(feature.bar?).to eq false
          expect(feature.instance_variables).not_to include(:@foo)
          expect(feature.instance_variables).not_to include(:@bar)

          feature.set_foo
          feature.set_bar
          expect(feature.foo).to eq 1
          expect(feature.bar?).to eq true
        end
      end
    end

    describe 'initialオプション' do
      let(:feature) do
        create_feature do
          def set_foo; @foo = 1; end
          def set_bar; @bar = true; end
          def initial_foo_value; 2; end
          def initial_bar_value; false; end
        end
      end

      context 'ブロックが指定された場合' do
        it 'ブロックの評価結果を、プロパティの初期値とする' do
          define_property(feature, :foo, initial: -> { initial_foo_value })
          define_property(feature, :bar?, initial: -> { initial_bar_value })

          expect(feature.foo).to eq 2
          expect(feature.bar?).to eq false
          expect(feature.instance_variables).to include(:@foo)
          expect(feature.instance_variables).to include(:@bar)

          feature.set_foo
          feature.set_bar
          expect(feature.foo).to eq 1
          expect(feature.bar?).to eq true
        end
      end

      context 'ブロック以外が指定された場合' do
        it '指定された値を、プロパティの初期値とする' do
          define_property(feature, :foo, initial: 0)
          define_property(feature, :bar?, initial: false)

          expect(feature.foo).to eq 0
          expect(feature.bar?).to eq false
          expect(feature.instance_variables).to include(:@foo)
          expect(feature.instance_variables).to include(:@bar)

          feature.set_foo
          feature.set_bar
          expect(feature.foo).to eq 1
          expect(feature.bar?).to eq true
        end
      end
    end

    describe 'forward_to_helper' do
      let(:feature) do
        create_feature do
          class << self
            def foo; 2; end
            def bar(v, &b); v + b.call; end
          end

          def initialize; @foo = 1; end
        end
      end

      context 'trueが指定された場合' do
        it 'ヘルパーメソッドに委譲するプロパティを定義する' do
          define_property(feature, :foo, forward_to_helper: true)
          expect(feature.foo).to eq 2
        end

        specify '定義されるプロパティは引数とブロックを取ることができる' do
          define_property(feature, :bar, forward_to_helper: true)
          expect(feature.bar(2) { 3 }).to eq 5
        end
      end

      context 'falseが指定された場合' do
        it '通常のプロパティを定義する' do
          define_property(feature, :foo, forward_to_helper: false)
          expect(feature.class).not_to receive(:foo)
          expect(feature.foo).to eq 1
        end
      end
    end

    describe 'forward_toオプション' do
      let(:feature) do
        create_feature do
          def foo; 1; end
          def bar(v, &b); v + b.call; end
        end
      end

      it '指定されたメソッドに委譲するプロパティを定義する' do
        define_property(feature, :foofoo, forward_to: :foo)
        expect(feature).to receive(:foo).and_call_original
        expect(feature.foofoo).to eq 1
      end

      specify '定義されるプロパティは引数とブロックを取ることができる' do
        define_property(feature, :barbar, forward_to: :bar)
        expect(feature.barbar(2) { 3 }).to eq 5
      end
    end

    describe 'verifyオプション' do
      let(:feature) { create_feature }

      it '指定された検証範囲で検証を行う' do
        define_property(feature, :foo, verify: :component)
        define_property(feature, :bar, verify: :all)

        expect(feature).to receive(:verify).with(:component)
        feature.foo

        expect(feature).to receive(:verify).with(:all)
        feature.bar
      end

      context '未指定の場合' do
        it 'プロパティ呼び出し時に、検証を実施しない' do
          define_property(feature, :foo)
          expect(feature).not_to receive(:verify)
          feature.foo
        end
      end
    end
  end
end

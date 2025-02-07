# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::Property do
  def create_feature(&body)
    Class.new(&body).new
  end

  def create_property(name, **options, &body)
    described_class.new(name, **options, &body)
  end

  context 'プロパティ名のみ与えられた場合' do
    let(:feature) do
      create_feature do
        def initialize; @foo = 1; end
      end
    end

    it '同名のフィーチャー上のインスタンス変数を返すプロパティを定義する' do
      property = create_property(:foo)
      expect(property.evaluate(feature)).to eq 1
    end
  end

  context '末尾に ? が付くプロパティ名が与えられた場合' do
    let(:feature) do
      create_feature do
        def initialize; @foo = 1; end
      end
    end

    it '同名(?は除く)のフィーチャー上のインスタンス変数を返すプロパティを定義する' do
      property = create_property(:foo?)
      expect(property.evaluate(feature)).to eq 1
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
      property = create_property(:foo) { @foo }
      expect(property.evaluate(feature)).to eq 1

      property = create_property(:barbar) { 2 * bar }
      expect(property.evaluate(feature)).to eq 4
    end

    specify '定義されたプロパティは引数、ブロックを取れる' do
      property = create_property(:foo) { |v, vv:, &b| v + vv + b.call }
      expect(property.evaluate(feature, 2, vv: 3) { 4 }).to eq 9
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
      property = create_property(:foo, body: -> { @foo })
      expect(property.evaluate(feature)).to eq 1

      property = create_property(:barbar, body: ->  { 2 * bar })
      expect(property.evaluate(feature)).to eq 4
    end

    specify '定義されたプロパティは引数、ブロックを取れる' do
      property = create_property(:foo, body: ->(v, vv:, &b) { v + vv + b.call })
      expect(property.evaluate(feature, 2, vv: 3) { 4 }).to eq 9
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
        foo_property = create_property(:foo, default: -> { default_foo_value } )
        bar_property = create_property(:bar?, default: -> { default_bar_value } )

        expect(foo_property.evaluate(feature)).to eq 2
        expect(bar_property.evaluate(feature)).to eq false
        expect(feature.instance_variables).not_to include(:@foo)
        expect(feature.instance_variables).not_to include(:@bar)

        feature.set_foo
        feature.set_bar
        expect(foo_property.evaluate(feature)).to eq 1
        expect(bar_property.evaluate(feature)).to eq true
      end
    end

    context 'ブロック以外を与えた場合' do
      it '指定された値を、プロパティの既定値とする' do
        foo_property = create_property(:foo, default: 0)
        bar_property = create_property(:bar?, default: false)

        expect(foo_property.evaluate(feature)).to eq 0
        expect(bar_property.evaluate(feature)).to eq false
        expect(feature.instance_variables).not_to include(:@foo)
        expect(feature.instance_variables).not_to include(:@bar)

        feature.set_foo
        feature.set_bar
        expect(foo_property.evaluate(feature)).to eq 1
        expect(bar_property.evaluate(feature)).to eq true
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
        foo_property = create_property(:foo, initial: -> { initial_foo_value })
        bar_property = create_property(:bar?, initial: -> { initial_bar_value })

        expect(foo_property.evaluate(feature)).to eq 2
        expect(bar_property.evaluate(feature)).to eq false
        expect(feature.instance_variables).to include(:@foo)
        expect(feature.instance_variables).to include(:@bar)

        feature.set_foo
        feature.set_bar
        expect(foo_property.evaluate(feature)).to eq 1
        expect(bar_property.evaluate(feature)).to eq true
      end
    end

    context 'ブロック以外が指定された場合' do
      it '指定された値を、プロパティの初期値とする' do
        foo_property = create_property(:foo, initial: 0)
        bar_property = create_property(:bar?, initial: false)

        expect(foo_property.evaluate(feature)).to eq 0
        expect(bar_property.evaluate(feature)).to eq false
        expect(feature.instance_variables).to include(:@foo)
        expect(feature.instance_variables).to include(:@bar)

        feature.set_foo
        feature.set_bar
        expect(foo_property.evaluate(feature)).to eq 1
        expect(bar_property.evaluate(feature)).to eq true
      end
    end
  end

  describe 'forward_to_helper' do
    let(:feature) do
      create_feature do
        class << self
          def foo; 2; end
          def bar(v, vv:, &b); v + vv + b.call; end
        end

        def initialize; @foo = 1; end
      end
    end

    context 'trueが指定された場合' do
      it 'ヘルパーメソッドに委譲するプロパティを定義する' do
        property = create_property(:foo, forward_to_helper: true)
        expect(property.evaluate(feature)).to eq 2
      end

      specify '定義されるプロパティは引数とブロックを取ることができる' do
        property = create_property(:bar, forward_to_helper: true)
        expect(property.evaluate(feature, 2, vv: 3) { 4 }).to eq 9
      end
    end

    context 'falseが指定された場合' do
      it '通常のプロパティを定義する' do
        property = create_property(:foo, forward_to_helper: false)
        expect(feature.class).not_to receive(:foo)
        expect(property.evaluate(feature)).to eq 1
      end
    end
  end

  describe 'forward_toオプション' do
    let(:feature) do
      create_feature do
        def foo; 1; end
        def bar(v, vv:, &b); v + vv + b.call; end
      end
    end

    it '指定されたメソッドに委譲するプロパティを定義する' do
      property = create_property(:foofoo, forward_to: :foo)
      expect(feature).to receive(:foo).and_call_original
      expect(property.evaluate(feature)).to eq 1
    end

    specify '定義されるプロパティは引数とブロックを取ることができる' do
      property = create_property(:barbar, forward_to: :bar)
      expect(property.evaluate(feature, 2, vv: 3) { 4 }).to eq 9
    end
  end

  describe 'verifyオプション' do
    let(:feature) { create_feature }

    it '指定された検証範囲で検証を行う' do
      property_foo = create_property(:foo, verify: :component)
      property_bar = create_property(:bar, verify: :all)

      expect(feature).to receive(:verify).with(:component)
      property_foo.evaluate(feature)

      expect(feature).to receive(:verify).with(:all)
      property_bar.evaluate(feature)
    end

    context '未指定の場合' do
      it 'プロパティ呼び出し時に、検証を実施しない' do
        property = create_property(:foo)

        expect(feature).not_to receive(:verify)
        property.evaluate(feature)
      end
    end
  end
end

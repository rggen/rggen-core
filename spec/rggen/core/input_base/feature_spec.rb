# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::Feature do
  def define_feature(base = described_class, &body)
    Class.new(base, &body)
  end

  def create_feature(base = described_class, &body)
    klass = define_feature(base, &body)
    component = RgGen::Core::Base::Component.new(nil, 'component', nil)
    klass.new(:feature, nil, component)
  end

  def create_input_value(value, *args)
    if args.empty?
      RgGen::Core::InputBase::InputValue.new(value, nil)
    else
      RgGen::Core::InputBase::InputValue.new(value, *args)
    end
  end

  describe '.property' do
    it 'プロパティを定義する' do
      expect(define_feature { property :foo }).to have_property :foo
    end

    specify '定義済みのプロパティは.propertiesで参照できる' do
      feature = define_feature { property :foo; property :bar }
      expect(feature.properties).to match [:foo, :bar]
    end

    specify '定義したプロパティは継承される' do
      parent = define_feature { property :foo; property :bar }
      feature = define_feature(parent) { property :baz }
      expect(feature.properties).to match [:foo, :bar, :baz]
    end

    context '同名のプロパティを複数定義した場合' do
      let(:feature) do
        create_feature do
          property(:foo) { foo_0 }
          property(:foo) { foo_1 }
        end
      end

      it '後の定義を優先する' do
        expect(feature).not_to receive(:foo_0)
        expect(feature).to receive(:foo_1)
        feature.foo
      end

      specify '.propertiesへの追加は1度だけ行う' do
        expect(feature.properties).to match [:foo]
      end
    end

    specify '.fieldでもプロパティを定義できる' do
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

  describe '#build' do
    let(:feature) do
      create_feature do
        build { |*args| foo(*args.map(&method(:extract_value))) }

        def extract_value(arg)
          arg.respond_to?(:value) && arg.value || arg
        end
      end
    end

    let(:child_feature) do
      create_feature(feature.class) do
        build { |*args| bar(*args.map(&method(:extract_value))) }
      end
    end

    let(:grandchild_feature) do
      create_feature(child_feature.class)
    end

    let(:value) { Object.new }

    let(:position) { Struct.new(:x, :y).new(0, 1) }

    let(:options) { [[], nil, false, Object.new].sample }

    let(:input_value_with_options) { create_input_value(value, options, position) }

    let(:input_value_without_options) { create_input_value(value, position) }

    let(:other_value) { Object.new }

    let(:other_position) { Struct.new(:a, :b).new(2, 3) }

    let(:other_input_value) { create_input_value(other_value, other_position) }

    it '.buildで登録されたブロックを実行し、フィーチャーの組み立てを行う' do
      expect(feature).to receive(:foo)
      feature.build(input_value_with_options)

      expect(feature).to receive(:foo)
      feature.build(input_value_without_options)
    end

    context '入力データがオプションを持たない場合' do
      specify '入力データが組み立てブロックに渡される' do
        expect(feature).to receive(:foo).with(equal(value))
        feature.build(input_value_without_options)

        expect(feature).to receive(:foo).with(equal(other_value), equal(value))
        feature.build(other_input_value, input_value_without_options)
      end
    end

    context '入力データがオプションを持つ場合' do
      specify '入力データとオプションが組み立てブロックに渡される' do
        expect(feature).to receive(:foo).with(equal(value), equal(options))
        feature.build(input_value_with_options)

        expect(feature).to receive(:foo).with(equal(other_value), equal(value), equal(options))
        feature.build(other_input_value, input_value_with_options)
      end
    end

    specify '入力データの#positionは、フィーチャー内に#positionとして保持される' do
      allow(feature).to receive(:foo)

      feature.build(input_value_without_options)
      expect(feature.send(:position)).to eq position

      feature.build(input_value_with_options)
      expect(feature.send(:position)).to eq position
    end

    specify '#positionの取り出しは、末尾の入力値に対して行われる' do
      allow(feature).to receive(:foo)

      feature.build(other_input_value, input_value_without_options)
      expect(feature.send(:position)).to eq position

      feature.build(other_input_value, input_value_with_options)
      expect(feature.send(:position)).to eq position
    end

    specify '登録された組み立てブロックは、継承される' do
      expect(grandchild_feature).to receive(:foo).with(equal(value))
      expect(grandchild_feature).to receive(:bar).with(equal(value))
      grandchild_feature.build(input_value_without_options)
    end

    it '組み立てブロックの登録がなくても、実行できる' do
      expect {
        create_feature.build(input_value_without_options)
      }.not_to raise_error
    end

    specify '組みてたブロックの登録があるフィーチャーを能動フィーチャーとする' do
      feature = create_feature { build {} }
      expect(feature).to be_active_feature
      expect(feature.class).to be_active_feature
      expect(feature).not_to be_passive_feature
      expect(feature.class).not_to be_passive_feature
    end

    specify '組みてたブロックの登録がないフィーチャーを受動フィーチャーとする' do
      feature = create_feature
      expect(feature).not_to be_active_feature
      expect(feature.class).not_to be_active_feature
      expect(feature).to be_passive_feature
      expect(feature.class).to be_passive_feature
    end
  end

  describe '#post_build' do
    let(:feature) do
      create_feature do
        post_build { foo }
      end
    end

    let(:child_feature) do
      create_feature(feature.class) do
        post_build { bar }
      end
    end

    let(:grandchild_feature) do
      create_feature(child_feature.class)
    end

    it 'フィーチャー組み立て後の後処理として、.post_buildで登録したブロックを実行しする' do
      expect(feature).to receive(:foo)
      feature.post_build
    end

    specify '登録された後処理ブロックは継承される' do
      expect(grandchild_feature).to receive(:foo)
      expect(grandchild_feature).to receive(:bar)
      grandchild_feature.post_build
    end

    it '後処理ブロックの登録がなくても、実行できる' do
      expect {
        create_feature.post_build
      }.not_to raise_error
    end
  end

  describe '#match_pattern' do
    it '.input_patternで登録されたパターンで、一致比較を行う' do
      feature = create_feature { input_pattern /foo/ }
      expect(feature.send(:match_pattern, 'foo')).to match([be_instance_of(MatchData), 0])
      expect(feature.send(:match_pattern, 'bar')).to be_falsey
    end

    it 'InputMatcher#matchを用いて、一致比較を行う' do
      feature = create_feature { input_pattern /foo/ }
      expect_any_instance_of(RgGen::Core::InputBase::InputMatcher).to receive(:match)
      feature.send(:match_pattern, 'foo')
    end

    specify 'パターン登録時に、InputMatcherに対して、オプションやブロックを渡すことができる' do
      feature = create_feature do
        input_pattern(/(foo)(bar)/, match_wholly: false) { |m| m.captures.map(&:upcase) }
      end
      expect(feature.send(:match_pattern, ' foobar ')).to match([match(['FOO', 'BAR']), 0])
    end

    describe '#match_data/#match_index' do
      let(:foo_feature) { create_feature { input_pattern(/foo/) } }
      let(:bar_feature) { create_feature { input_pattern(/bar/) { |m| m[0].upcase } }}
      let(:foo_bar_feature) { create_feature { input_pattern([{ foo: /foo/, bar: /bar/ }]) } }

      it '直近の比較結果を返す' do
        foo_feature.send(:match_pattern, 'foo')
        expect(foo_feature.send(:match_data)[0]).to eq 'foo'
        expect(foo_feature.send(:match_index)).to eq 0

        foo_feature.send(:match_pattern, 'bar')
        expect(foo_feature.send(:match_data)).to be_nil
        expect(foo_feature.send(:match_index)).to be_nil

        bar_feature.send(:match_pattern, 'bar')
        expect(bar_feature.send(:match_data)).to eq 'BAR'
        expect(bar_feature.send(:match_index)).to eq 0

        bar_feature.send(:match_pattern, 'foo')
        expect(bar_feature.send(:match_data)).to be_nil
        expect(bar_feature.send(:match_index)).to be_nil

        foo_bar_feature.send(:match_pattern, 'foo')
        expect(foo_bar_feature.send(:match_data)[0]).to eq 'foo'
        expect(foo_bar_feature.send(:match_index)).to eq :foo

        foo_bar_feature.send(:match_pattern, 'bar')
        expect(foo_bar_feature.send(:match_data)[0]).to eq 'bar'
        expect(foo_bar_feature.send(:match_index)).to eq :bar
      end
    end

    describe '#pattern_matched?' do
      let(:feature) { create_feature { input_pattern /foo/ } }

      it '直近の比較が成功したかどうかを返す' do
        feature.send(:match_pattern, 'foo')
        expect(feature.send(:pattern_matched?)).to be true
        feature.send(:match_pattern, 'bar')
        expect(feature.send(:pattern_matched?)).to be false
      end
    end

    describe 'match_automaticallyオプション' do
      let(:input_values) { [:foo, :bar].map { |value| create_input_value(value) } }

      context 'trueが設定された場合' do
        let(:feature) do
          create_feature do
            input_pattern /foo/, match_automatically: true
            build {}
          end
        end

        it '#build実行時に、自動で末尾の引数に対して一致比較を行う' do
          expect(feature).to receive(:match_pattern).with(eq(:bar))
          feature.build(*input_values)
        end
      end

      context 'falseが設定された場合' do
        let(:feature) do
          create_feature do
            input_pattern /foo/, match_automatically: false
            build {}
          end
        end

        it '#build実行時に、自動で一致比較を行わない' do
          expect(feature).not_to receive(:match_pattern)
          feature.build(*input_values)
        end
      end

      context '設定がない場合' do
        let(:feature) do
          create_feature do
            input_pattern /foo/
            build {}
          end
        end

        it '#build実行時に、自動で一致比較を行う' do
          expect(feature).to receive(:match_pattern)
          feature.build(*input_values)
        end
      end
    end

    specify 'パターンは継承される' do
      feature = create_feature(define_feature {
        input_pattern /foo/
        build {}
      })
      feature.build(create_input_value(:foo))
      expect(feature.send(:pattern_matched?)).to be true
    end
  end

  describe '#verify' do
    let(:feature) do
      create_feature do
        verify(:feature) do
          error_condition { condition_foo_0 }
          message { message_foo_0 }
        end
        verify(:component) do
          error_condition { condition_bar_0 }
          message { message_bar_0 }
        end
        verify(:all) do
          error_condition { condition_baz_0 }
          message { message_baz_0 }
        end

        def error(message)
          raise message
        end
      end
    end

    let(:child_feature) do
      create_feature(feature.class) do
        verify(:feature) do
          error_condition { condition_foo_1 }
          message { message_foo_1 }
        end
        verify(:component) do
          error_condition { condition_bar_1 }
          message { message_bar_1 }
        end
        verify(:all) do
          error_condition { condition_baz_1 }
          message { message_baz_1 }
        end
      end
    end

    let(:grandchild_feature) do
      create_feature(child_feature.class)
    end

    context '検証範囲が:featureの場合' do
      it '.verify(:feature)で登録された検証ブロックを実行し、フィーチャーの検証を行う' do
        expect(feature).to receive(:condition_foo_0).and_return(true)
        expect(feature).to receive(:message_foo_0).and_return('error foo 0')
        expect { feature.verify(:feature) }.to raise_error('error foo 0')
      end
    end

    context '検証範囲が:componentの場合' do
      it '.verify(:component)で登録された検証ブロックを実行し、コンポーネントの検証を行う' do
        expect(feature).to receive(:condition_bar_0).and_return(true)
        expect(feature).to receive(:message_bar_0).and_return('error bar 0')
        expect { feature.verify(:component) }.to raise_error('error bar 0')
      end
    end

    context '検証範囲が:allの場合' do
      it '.verify(:all)で登録された検証ブロックを実行し、全体の検証を行う' do
        expect(feature).to receive(:condition_baz_0).and_return(true)
        expect(feature).to receive(:message_baz_0).and_return('error baz 0')
        expect { feature.verify(:all) }.to raise_error('error baz 0')
      end
    end

    specify '検証は一度だけ行われる' do
      expect(feature).to receive(:condition_foo_0).once.and_return(false)
      expect(feature).to receive(:condition_bar_0).once.and_return(false)
      expect(feature).to receive(:condition_baz_0).once.and_return(false)

      2.times do
        feature.verify(:feature)
        feature.verify(:component)
        feature.verify(:all)
      end
    end

    specify '登録された検証ブロックは継承される' do
      expect(grandchild_feature).to receive(:condition_foo_0).and_return(false)
      expect(grandchild_feature).to receive(:condition_foo_1).and_return(false)
      grandchild_feature.verify(:feature)

      expect(grandchild_feature).to receive(:condition_bar_0).and_return(false)
      expect(grandchild_feature).to receive(:condition_bar_1).and_return(false)
      grandchild_feature.verify(:component)

      expect(grandchild_feature).to receive(:condition_baz_0).and_return(false)
      expect(grandchild_feature).to receive(:condition_baz_1).and_return(false)
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

  describe '#printables' do
    context '.printableに表示可能オブジェクト名のみ与えられた場合' do
      let(:feature) do
        create_feature do
          printable(:foo)
          printable(:bar)
          def foo; 1; end
          def bar; 2; end
        end
      end

      it '同名のメソッドの戻り値を表示可能オブジェクトとして返す' do
        expect(feature.printables).to match([[:foo, 1], [:bar, 2]])
      end
    end

    context '.printableにブロックも与えられた場合' do
      let(:feature) do
        create_feature do
          printable(:foo) { 2 * foo }
          printable(:bar) { 2 * bar }
          def foo; 1; end
          def bar; 2; end
        end
      end

      it 'ブロックを評価し、表示可能オブジェクトとして返す' do
        expect(feature.printables).to match([[:foo, 2], [:bar, 4]])
      end
    end

    context '継承された場合' do
      let(:feature) do
        create_feature do
          printable(:foo)
          printable(:bar) { 2 * bar }
          def foo; 1; end
          def bar; 2; end
        end
      end

      specify '.printableで指定された表示可能オブジェクトは子クラスに引き継がれる' do
        child_feature = create_feature(feature.class)
        expect(child_feature.printables).to match([[:foo, 1], [:bar, 4]])
      end

      specify '子クラスでのブロックの再指定は、親クラスに影響しない' do
        create_feature(feature.class) do
          printable(:foo) { 3 * foo }
          printable(:bar) { 3 * bar }
        end
        expect(feature.printables).to match([[:foo, 1], [:bar, 4]])
      end
    end
  end

  describe '#printable?' do
    context '.printableでブロックが指定されている場合' do
      let(:feature) do
        create_feature { printable(:foo) { 'foo' } }
      end

      it '真を返す' do
        expect(feature).to be_printable
      end
    end

    context '.printableでブロックが指定されていない場合' do
      let(:feature) do
        create_feature
      end

      it '偽を返す' do
        expect(feature).not_to be_printable
      end
    end
  end

  describe '#error_position' do
    let(:foo_position) do
      Struct.new(:x, :y).new(0, 1)
    end

    let(:bar_position) do
      Struct.new(:x, :y).new(1, 2)
    end

    let(:input_values) do
      [
        create_input_value(Object.new, foo_position),
        create_input_value(Object.new, bar_position)
      ]
    end

    let(:component) do
      RgGen::Core::Base::Component.new(nil, "component", nil)
    end

    let(:features) do
      foo_feature = define_feature { build { |arg| @foo = arg } }.new(:foo, nil, component)
      component.add_feature(foo_feature)

      bar_feature = define_feature { build { |arg| @bar = arg } }.new(:bar, nil, component)
      component.add_feature(bar_feature)

      baz_feature = define_feature { build { |arg| @baz = arg } }.new(:baz, nil, component)
      component.add_feature(baz_feature)

      [foo_feature, bar_feature, baz_feature]
    end

    context '#positionを持つ場合' do
      it '正確なエラー位置として#positionを返す' do
        features[0].build(input_values[0])
        features[1].build(input_values[1])

        expect(features[0].error_position).to equal(foo_position)
        expect(features[1].error_position).to equal(bar_position)
      end
    end

    context '#positionを持たない場合' do
      it 'おおよそのエラー位置として、最初に明示されたfeatureの#positionを返す' do
        features[1].build(input_values[1])

        expect(features[0].error_position)
          .to be_instance_of(RgGen::Core::InputBase::ApproximatelyErrorPosition)
          .and match_string("#{bar_position} (approximately)")
        expect(features[2].error_position)
          .to be_instance_of(RgGen::Core::InputBase::ApproximatelyErrorPosition)
          .and match_string("#{bar_position} (approximately)")
      end
    end
  end

  describe '#inspect' do
    context '表示可能オブジェクトを含む場合' do
      let(:feature) do
        create_feature do
          printable(:foo) { :foo }
          printable(:bar) { [:bar_0, :bar_1] }
        end
      end

      it '表示可能オブジェクトも表示する' do
        expect(feature.inspect).to eq 'feature(component)[foo: :foo, bar: [:bar_0, :bar_1]]'
      end
    end

    context '表示可能オブジェクトを含まない場合' do
      let(:feature) do
        create_feature {}
      end

      it 'フィーチャー名と、コンポーネント名のみを表示する' do
        expect(feature.inspect).to eq 'feature(component)'
      end
    end
  end
end

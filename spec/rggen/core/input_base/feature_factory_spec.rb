# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::FeatureFactory do
  let(:feature_name) do
    :feature_name
  end

  let(:active_feature) do
    Class.new(RgGen::Core::InputBase::Feature) { build {} }
  end

  let(:passive_feature) do
    Class.new(RgGen::Core::InputBase::Feature)
  end

  let(:exception) do
    Class.new(RgGen::Core::RgGenError)
  end

  let(:feature_factory) do
    e = exception
    Class.new(described_class) do
      define_method(:error_exception) { e }
    end
  end

  describe '#create' do
    let(:component) { RgGen::Core::Base::Component.new(nil, 'component', nil) }

    let(:active_factory) do
      feature_factory.new(feature_name) { |f| f.target_feature active_feature }
    end

    let(:passive_factory) do
      feature_factory.new(feature_name) { |f| f.target_feature passive_feature }
    end

    let(:input_value) { RgGen::Core::InputBase::InputValue.new(:foo, position) }

    let(:position) { Struct.new(:x, :y).new(0, 1) }

    def create_input_value(value)
      RgGen::Core::InputBase::InputValue.new(value, position)
    end

    it '#create_featureを呼んで、フィーチャーを生成する' do
      expect(active_factory).to receive(:create_feature).and_call_original
      expect(passive_factory).to receive(:create_feature).and_call_original
      active_factory.create(component, :other_arg, input_value)
      passive_factory.create(component)
    end

    describe 'フィーチャーの組み立て' do
      it '末尾の引数を用いて、フィーチャーの組み立てを行う' do
        expect_any_instance_of(active_feature).to receive(:build).with(equal(input_value))
        active_factory.create(component, :other_arg, input_value)
      end

      context '入力が欠損値の場合' do
        it 'フィーチャーの組み立てを行わない' do
          expect_any_instance_of(active_feature).not_to receive(:build)

          active_feature.send(:ignore_empty_value, true)
          active_factory.create(component, :other_arg, RgGen::Core::InputBase::NAValue)

          active_feature.send(:ignore_empty_value, false)
          active_factory.create(component, :other_arg, RgGen::Core::InputBase::NAValue)
        end
      end

      context '入力データが空データで' do
        let(:empty_value) { RgGen::Core::InputBase::InputValue.new('', nil) }

        context '対象フィーチャーが空データを無視する場合' do
          let(:active_feature) do
            Class.new(RgGen::Core::InputBase::Feature) do
              ignore_empty_value true
              build {}
            end
          end

          it 'フィーチャーの組み立てを行わない' do
            expect_any_instance_of(active_feature).not_to receive(:build)
            active_factory.create(component, :other_arg, empty_value)
          end
        end

        context '対象フィーチャーが空データを無視しない場合' do
          let(:active_feature) do
            Class.new(RgGen::Core::InputBase::Feature) do
              ignore_empty_value false
              build {}
            end
          end

          it 'フィーチャーの組み立てを行う' do
            expect_any_instance_of(active_feature).to receive(:build)
            active_factory.create(component, :other_arg, empty_value)
          end
        end
      end

      context '対象フィーチャーが受動フィーチャーの場合' do
        it 'フィーチャーの組み立てを行わない' do
          expect_any_instance_of(passive_feature).not_to receive(:build)
          passive_factory.create(component)
        end
      end
    end

    describe 'フィーチャーの検証' do
      let(:features) do
        [
          Class.new(RgGen::Core::InputBase::Feature) { ignore_empty_value false; build {} },
          Class.new(RgGen::Core::InputBase::Feature) { ignore_empty_value true; build {} },
          Class.new(RgGen::Core::InputBase::Feature)
        ]
      end

      let(:feature_factories) do
        features.map do |feature|
          feature_factory.new(feature_name) { |f| f.target_feature feature }
        end
      end

      it 'Feature#buildの呼び出しにかかわらず、#verifyを呼び出して、フィーチャーの検証を行う' do
        expect_any_instance_of(features[0]).to receive(:verify).with(:feature).and_call_original
        feature_factories[0].create(component, :other_arg, RgGen::Core::InputBase::NAValue)

        expect_any_instance_of(features[1]).to receive(:verify).with(:feature).and_call_original
        feature_factories[1].create(component, :other_arg, RgGen::Core::InputBase::NAValue)

        expect_any_instance_of(features[2]).to receive(:verify).with(:feature).and_call_original
        feature_factories[2].create(component)
      end
    end

    describe '既定値の設定' do
      let(:feature_class) do
        Class.new(RgGen::Core::InputBase::Feature) do
          property :value
          build { |value| @value = value }
        end
      end

      let(:factory_class) do
        Class.new(feature_factory) do
          default_value { default_value }
          def default_value; :foo; end
        end
      end

      let(:active_factory) do
        factory_class.new(feature_name) { |f| f.target_feature feature_class }
      end

      let(:passive_factory) do
        factory_class.new(feature_name) { |f| f.target_feature passive_feature }
      end

      let(:feature) { active_factory.create(component, input_value) }

      def create_feature(factory, value = nil)
        factory.create(component, value || RgGen::Core::InputBase::NAValue)
      end

      context '入力が欠損値の場合' do
        it '.default_valueで登録されたブロックを実行し、既定値とする' do
          expect(active_factory).to receive(:default_value).and_call_original
          expect(create_feature(active_factory, RgGen::Core::InputBase::NAValue).value).to eq :foo
        end
      end

      context '入力が空白の場合' do
        let(:empty_value) { RgGen::Core::InputBase::InputValue.new('', nil) }

        it '.default_valueで登録されたブロックを実行し、既定値とする' do
          expect(active_factory).to receive(:default_value).and_call_original
          expect(create_feature(active_factory, empty_value).value).to eq :foo
        end
      end

      context '入力が空データではない場合' do
        it '規定値の設定を行わない' do
          expect(active_factory).not_to receive(:default_value)
          create_feature(active_factory, input_value)
        end
      end

      it '対象フィーチャーが受動フィーチャーの場合は、入力値の変換を行わない' do
        expect(passive_factory).not_to receive(:default_value)
        create_feature(passive_factory)
      end
    end

    describe '入力値の変換' do
      let(:feature_class) do
        Class.new(RgGen::Core::InputBase::Feature) do
          property :value
          build { |value| @value = value }
        end
      end

      let(:factory_class) do
        Class.new(feature_factory) do
          convert_value { |value| upcase(value) }
          def upcase(value); value.upcase end
        end
      end

      let(:active_factory) do
        factory_class.new(feature_name) { |f| f.target_feature feature_class }
      end

      let(:passive_factory) do
        factory_class.new(feature_name) { |f| f.target_feature passive_feature }
      end

      let(:feature) { active_factory.create(component, input_value) }

      it '.convert_valueで登録されたブロックを実行し、入力値の変換を行う' do
        expect(active_factory).to receive(:upcase).and_call_original
        expect(feature.value).to eq :FOO
      end

      specify '変換後も位置情報は維持される' do
        expect(feature.send(:position)).to eq position
      end

      specify '引数として与えられた入力値は変化しない' do
        active_factory.create(component, input_value)
        expect(input_value.value).to eq :foo
      end

      it '入力が空データの場合は、入力値の変換を行わない' do
        expect(active_factory).not_to receive(:upcase)
        active_factory.create(component, RgGen::Core::InputBase::NAValue)
      end

      it '対象フィーチャーが受動フィーチャーの場合は、入力値の変換を行わない' do
        expect(passive_factory).not_to receive(:upcase)
        passive_factory.create(component, input_value)
      end
    end

    context 'value_formatにoption_arrayが指定されている場合' do
      let(:feature_class) do
        Class.new(RgGen::Core::InputBase::Feature) do
          property :value
          property :options
          build { |value, options| @value, @options = [value, options] }
        end
      end

      let(:factory_class) do
        Class.new(feature_factory) do
          value_format :option_array
        end
      end

      let(:factory) do
        factory_class.new(feature_name) { |f| f.target_feature feature_class }
      end

      specify '入力値にオプションをとることができる' do
        value = :foo
        options = [:bar, [:baz, 1], :qux]

        feature = factory.create(component, create_input_value([value, *options]))
        expect(feature.value).to eq value
        expect(feature.options).to match(options)

        feature = factory.create(component, create_input_value(value))
        expect(feature.value).to eq value
        expect(feature.options).to be_empty
      end

      specify '位置情報は維持される' do
        feature = factory.create(component, create_input_value(:foo))
        expect(feature.send(:position)).to eq position

        feature = factory.create(component, create_input_value('foo'))
        expect(feature.send(:position)).to eq position
      end

      context '入力値の変換が与えられている場合' do
        specify 'オプションには適用されない' do
          factory_class.class_eval do
            convert_value { |value| value.upcase }
          end

          value = 'foo'
          options = ['bar', 'baz']

          feature = factory.create(component, create_input_value([value, *options]))
          expect(feature.value).to eq value.upcase
          expect(feature.options).to match(options)
        end
      end
    end

    context 'value_formatにoption_hashが指定された場合' do
      let(:feature_class) do
        Class.new(RgGen::Core::InputBase::Feature) do
          property :v
          property :o
          build { |v, o| @v = v; @o = o }
        end
      end

      def factory(**options)
        klass =
          Class.new(feature_factory) do
            value_format :option_hash, **options
          end
        klass.new(feature_name) { |f| f.target_feature feature_class }
      end

      specify '入力値にハッシュ形式のオプションを取ることができる' do
        value = 0
        options = { foo: 1, bar: 2 }

        feature = factory.create(component, create_input_value([value, options]))
        expect(feature.v).to eq(value)
        expect(feature.o).to match(options)

        feature = factory.create(component, create_input_value(value))
        expect(feature.v).to eq(value)
        expect(feature.o).to be_empty

        feature = factory.create(component, create_input_value([value]))
        expect(feature.v).to eq(value)
        expect(feature.o).to be_empty
      end

      context 'multiple_valuesが指定された場合' do
        specify '複数の入力値を持つことができる' do
          values = [0, 1]
          options = { foo: 2, bar: 3 }

          feature = factory(multiple_values: true).create(component, create_input_value([*values, options]))
          expect(feature.v).to match(values)
          expect(feature.o).to match(options)
        end
      end

      context 'allowed_optionsが指定された場合' do
        specify '受け入れ可能なオプションが指定される' do
          allowed_options = [:foo, :bar]

          expect {
            factory(allowed_options: allowed_options).create(component, create_input_value([0, foo: 1, bar: 2]))
          }.to_not raise_error

          expect {
            factory(allowed_options: allowed_options).create(component, create_input_value([0, baz: 1, qux: 2]))
          }.to raise_error exception
        end
      end

      specify '位置情報は保持される' do
        feature = factory.create(component, create_input_value(0))
        expect(feature.send(:position)).to eq position

        feature = factory(multiple_values: true).create(component, create_input_value([0, 1]))
        expect(feature.send(:position)).to eq position
      end

      context '入力値の変換が与えられている場合' do
        specify 'オプションには適用されない' do
          f = factory
          f.class.class_eval do
            convert_value { |v| v - 1 }
          end

          value = 0
          options = { foo: 1, bar: 2 }

          feature = f.create(component, create_input_value([value, options]))
          expect(feature.v).to eq(value - 1)
          expect(feature.o).to match(options)
        end
      end
    end

    context 'value_formatにhash_listが指定された場合' do
      let(:feature_class) do
        Class.new(RgGen::Core::InputBase::Feature) do
          property :hash_list
          build { |hash_list| @hash_list = hash_list }
        end
      end

      let(:factory_class) do
        Class.new(feature_factory) do
          value_format :hash_list
        end
      end

      let(:factory) do
        factory_class.new(feature_name) { |f| f.target_feature feature_class }
      end

      specify 'ハッシュのリストとして入力を受け付ける' do
        input_value = create_input_value([
          { foo: 0, bar: 1 },
          { foo: 2, bar: 3 }
        ])
        feature = factory.create(component, input_value)
        expect(feature.hash_list[0]).to match(foo: 0, bar: 1)
        expect(feature.hash_list[1]).to match(foo: 2, bar: 3)

        input_value = create_input_value(<<~'HASH_LIST')
          foo: 0, bar: 1

          foo: 2
          bar: 3
        HASH_LIST
        feature = factory.create(component, input_value)
        expect(feature.hash_list[0]).to match('foo' => '0', 'bar' => '1')
        expect(feature.hash_list[1]).to match('foo' => '2', 'bar' => '3')
      end

      specify '位置情報は維持される' do
        input_value = create_input_value([{ foo: 0 }])
        feature = factory.create(component, input_value)
        expect(feature.send(:position)).to eq position

        input_value = create_input_value('foo: 0')
        feature = factory.create(component, input_value)
        expect(feature.send(:position)).to eq position
      end

      context '入力値の変換が与えられた場合' do
        specify '全体に対して適用される' do
          factory_class.class_eval do
            convert_value do |hash_list|
              hash_list.each do |element|
                element.transform_values!(&:upcase)
              end
            end
          end

          input_value = create_input_value([
            { foo: 'foo_0', bar: 'bar_0' },
            { foo: 'foo_1', bar: 'bar_1' }
          ])
          feature = factory.create(component, input_value)
          expect(feature.hash_list).to match([
            { foo: 'FOO_0', bar: 'BAR_0' },
            { foo: 'FOO_1', bar: 'BAR_1' }
          ])
        end
      end
    end
  end

  describe '#active_feature_factory?/#passive_feature_factory?' do
    let(:simple_active_feature_factory) do
      feature_factory.new(feature_name) { |f| f.target_feature active_feature }
    end

    let(:simple_passive_feature_factory) do
      feature_factory.new(feature_name) { |f| f.target_feature passive_feature }
    end

    let(:multiple_features_factory) do
      feature_factory.new(feature_name) do |f|
        f.target_feature passive_feature
        f.target_features foo: active_feature, bar: passive_feature
      end
    end

    specify '能動フィーチャーを#target_featureに持つファクトリは能動フィーチャーファクトリ' do
      expect(simple_active_feature_factory).to be_active_feature_factory
      expect(simple_active_feature_factory).not_to be_passive_feature_factory
    end

    specify '受動フィーチャーを#target_featureに持つファクトリは受動フィーチャーファクトリ' do
      expect(simple_passive_feature_factory).not_to be_active_feature_factory
      expect(simple_passive_feature_factory).to be_passive_feature_factory
    end

    specify '#target_featuresを持つファクトリは能動フィーチャーファクトリ' do
      expect(multiple_features_factory).to be_active_feature_factory
      expect(multiple_features_factory).not_to be_passive_feature_factory
    end
  end
end

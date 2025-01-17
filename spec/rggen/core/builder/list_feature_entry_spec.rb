# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::ListFeatureEntry do
  let(:feature_name) { :feature }

  let(:feature_base) { RgGen::Core::InputBase::Feature }

  let(:factory_base) do
    Class.new(RgGen::Core::InputBase::FeatureFactory) do
      def create(*args)
        create_feature(*args)
      end
    end
  end

  let(:component) { RgGen::Core::InputBase::Component.new(nil, :component, nil) }

  let(:feature_registry) { double('feature_registry') }

  let(:default_factory_body) do
    proc { def target_feature_key(key); key; end }
  end

  def create_entry(context = nil, &body)
    entry = described_class.new(feature_registry, feature_name)
    entry.setup(feature_base, factory_base, context)
    entry.eval_bodies([body])
    entry
  end

  describe 'ファクトリの定義' do
    specify '#build_factoryでエントリー生成時に指定したファクトリを生成する' do
      entry = create_entry
      factory = entry.build_factory([])
      expect(factory).to be_kind_of factory_base
      expect(factory).not_to be_instance_of factory_base
    end

    specify '#define_factory/#factoryでファクトリの定義を行える' do
      entry = create_entry do
        define_factory { def foo = 'foo!' }
        factory { def bar = 'bar!' }
      end

      factory = entry.build_factory(nil)
      expect(factory.foo).to eq 'foo!'
      expect(factory.bar).to eq 'bar!'
    end
  end

  describe 'フィーチャーの定義' do
    specify '生成したファクトリで、#define_feature/#featureで定義したフィーチャーを生成できる' do
      entry = create_entry do
        define_factory(&default_factory_body)
        define_feature(:foo, nil, [proc { def m = 'foo!' }])
        feature(:bar, nil, [proc { def m = 'bar!' }])
      end
      factory = entry.build_factory(nil)

      feature = factory.create(component, :foo)
      expect(feature.m).to eq 'foo!'

      feature = factory.create(component, :bar)
      expect(feature.m).to eq 'bar!'
    end

    describe '#modify_feature' do
      specify '#modify_featureで既存のフィーチャーを変更できる' do
        entry = create_entry do
          define_factory(&default_factory_body)
          define_feature(:foo, nil, [proc { def m = 'foo!' }])
          modify_feature(:foo, [proc { def m = 'foo!!' }])
        end
        factory = entry.build_factory(nil)

        feature = factory.create(component, :foo)
        expect(feature.m).to eq 'foo!!'
      end

      context '指定したフィーチャーが定義されていない場合' do
        it 'BuilderErrorを起こす' do
          expect {
            create_entry do
              define_feature(:foo, nil, [])
              modify_feature(:bar, [])
            end
          }.to raise_error RgGen::Core::BuilderError, 'unknown feature: bar'
        end
      end
    end

    context '同名のフィーチャーが複数回定義された場合' do
      specify '最後に定義されたフィーチャーが生成される' do
        entry = create_entry do
          define_factory(&default_factory_body)
          define_feature(:foo, nil, [proc { def fizz = 'fizz' }])
          define_feature(:foo, nil, [proc { def buzz = 'buzz' }])
        end
        factory = entry.build_factory(nil)

        feature = factory.create(component, :foo)
        expect(feature.buzz).to eq 'buzz'
        expect { feature.fizz }.to raise_error NoMethodError
      end
    end

    context 'ファクトリ生成時にフィーチャーの指定がない場合' do
      specify '定義したフィーチャーすべてを生成できる' do
        exception = Class.new(StandardError)

        entry = create_entry do
          define_factory do
            define_method(:target_feature_key) do |key|
              (@target_features.key?(key) && key) || (raise exception)
            end
          end
          define_feature(:foo, nil, [])
          define_feature(:bar, nil, [])
          define_feature(:baz, nil, [])
        end

        factory = entry.build_factory(nil)
        expect {
          factory.create(component, :foo)
          factory.create(component, :bar)
          factory.create(component, :baz)
        }.not_to raise_error
      end
    end

    context 'ファクトリ生成時にフィーチャーの指定がある場合' do
      specify 'ファクトリ生成時に指定したフィーチャーを生成できる' do
        exception = Class.new(StandardError)

        entry = create_entry do
          define_factory do
            define_method(:target_feature_key) do |key|
              (@target_features.key?(key) && key) || (raise exception)
            end
          end
          define_feature(:foo, nil, [])
          define_feature(:bar, nil, [])
          define_feature(:baz, nil, [])
        end

        factory = entry.build_factory([:foo, :bar])
        expect {
          factory.create(component, :foo)
          factory.create(component, :bar)
        }.not_to raise_error
        expect {
          factory.create(component, :baz)
        }.to raise_error exception
      end
    end

    describe '既定フィーチャーの定義' do
      context '#define_featureで定義したフィーチャーから対象フィーチャーを選択できなかった場合' do
        specify '#define_deault_feature/default_featureで定義した既定フィーチャーが生成される' do
          entry = create_entry do
            define_factory(&default_factory_body)
            define_default_feature { def fizz = 'fizz!' }
            default_feature { def buzz = 'buzz!' }
          end

          feature = entry.build_factory(nil).create(component, :foo)
          expect(feature.fizz).to eq 'fizz!'
          expect(feature.buzz).to eq 'buzz!'
        end
      end
    end

    describe '親フィーチャーの定義' do
      specify '#define_base_feature/base_featureで各フィーチャーの親フィーチャーを定義できる' do
        entry = create_entry do
          define_factory(&default_factory_body)
          define_base_feature { def fizz = 'fizz!' }
          base_feature { def buzz = 'buzz!' }
          define_feature(:foo, nil, [])
          define_feature(:bar, nil, [])
          define_default_feature {}
        end

        factory = entry.build_factory(nil)
        [:foo, :bar, :baz].each do |feature_name|
          entry = factory.create(component, feature_name)
          expect(entry.fizz).to eq 'fizz!'
          expect(entry.buzz).to eq 'buzz!'
        end
      end
    end

    describe '定義したフィーチャーの削除' do
      let(:entry) do
        create_entry do
          define_factory(&default_factory_body)
          define_default_feature do
            def m = 'default'
          end
          define_feature(:foo, nil, [proc { def m = 'foo' }])
          define_feature(:bar, nil, [proc { def m = 'bar' }])
          define_feature(:baz, nil, [proc { def m = 'baz' }])
          define_feature(:qux, nil, [proc { def m = 'qux' }])
        end
      end

      context '#deleteを無引数で呼び出した場合' do
        it '定義済みフィーチャーを全て削除する' do
          entry.delete

          factory = entry.build_factory(nil)
          [:foo, :bar, :baz, :qux].each do |feature_name|
            entry = factory.create(component, feature_name)
            expect(entry.m).to eq 'default'
          end
        end
      end

      context '#deleteにフィーチャー名を与えた場合' do
        it '指定したフィーチャーを削除する' do
          entry.delete(:foo)
          entry.delete([:bar, :baz])

          factory = entry.build_factory(nil)
          [:foo, :bar, :baz, :qux].each do |feature_name|
            entry = factory.create(component, feature_name)
            if feature_name == :qux
              expect(entry.m).to eq 'qux'
            else
              expect(entry.m).to eq 'default'
            end
          end
        end
      end
    end

    specify 'エントリ生成時に指定した名称が、生成されるフィーチャーの名称になる' do
      entry = create_entry do
        define_factory(&default_factory_body)
        define_feature(:foo, nil, [])
        define_default_feature
      end

      factory = entry.build_factory(nil)
      [:foo, :bar].each do |key|
        feature = factory.create(component, key)
        expect(feature.feature_name).to eq feature_name
      end
    end
  end

  describe '共通コンテキスト' do
    context 'エントリー生成時に共通オブジェクトが与えられた場合' do
      specify 'エントリー/親フィーチャー/ファクトリに共通コンテキストが設定される' do
        shared_context = Object.new

        entry = create_entry(shared_context) do
          define_factory(&default_factory_body)
          define_feature(:foo, nil, [])
          define_default_feature
        end

        factory = entry.build_factory(nil)
        features = [factory.create(component, :foo), factory.create(component, :bar)]

        expect(entry.shared_context).to be shared_context
        expect(factory.shared_context).to be shared_context
        expect(features[0].shared_context).to be shared_context
        expect(features[1].shared_context).to be shared_context
      end
    end

    context 'フィーチャーの定義時に与えられた場合' do
      specify '定義したフィーチャーに共通コンテキストが設定される' do
        shared_contexts = { foo: Object.new, bar: Object.new }

        entry = create_entry do
          define_factory(&default_factory_body)
          define_feature(:foo, shared_contexts[:foo], [])
          define_feature(:bar, shared_contexts[:bar], [])
        end

        factory = entry.build_factory(nil)
        features = {}
        features[:foo] = factory.create(component, :foo)
        features[:bar] = factory.create(component, :bar)

        features.each do |feature_name, feature|
          expect(feature.shared_context).to be shared_contexts[feature_name]
        end
      end

      specify '共通コンテキストは複数回設定できない' do
        shared_context = Object.new

        entry = create_entry(shared_context)
        expect {
          entry.define_feature(:foo, shared_context, [])
        }.to raise_rggen_error RgGen::Core::BuilderError, 'shared context has already been set'
      end
    end
  end

  describe '#feature?' do
    let(:entry) do
      create_entry do
        define_feature(:foo, nil, [])
        define_feature(:bar, nil, [])
      end
    end

    it '定義済みのフィーチャーかどうかを返す' do
      expect(entry.feature?(:foo)).to be true
      expect(entry.feature?(:bar)).to be true
      expect(entry.feature?(:baz)).to be false
    end
  end
end

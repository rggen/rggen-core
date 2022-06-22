# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::FeatureRegistry do
  let(:base_feature) do
    RgGen::Core::InputBase::Feature
  end

  let(:feature_factory) do
    Class.new(RgGen::Core::InputBase::FeatureFactory) do
      def create(*args); create_feature(*args); end
      def target_feature_key(key); key; end
    end
  end

  let(:registry) do
    described_class.new(base_feature, feature_factory)
  end

  let(:component) do
    RgGen::Core::InputBase::Component.new(nil, :component, nil)
  end

  describe 'build_factories/#enable/#enable_all' do
    before do
      [:foo_0, :foo_1, :foo_2].each do |feature|
        registry.define_simple_feature(feature) do
          define_method(:m) { feature }
        end
      end
      [:bar_0].each do |feature|
        registry.define_list_feature(feature) do
          define_default_feature { define_method(:m) { feature } }
        end
      end
      [:bar_0_0, :bar_0_1, :bar_0_2, :bar_0_3].each do |feature|
        registry.define_list_item_feature(:bar_0, feature) do
          define_method(:m) { feature }
        end
      end
    end

    context '#enableで対象フィーチャーの指定がない場合' do
      it '定義したフィーチャーすべてのファクトリを生成する' do
        factories = registry.build_factories
        expect(factories.keys).to match([:foo_0, :foo_1, :foo_2, :bar_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:foo_1].create(component).m).to eq :foo_1
        expect(factories[:foo_2].create(component).m).to eq :foo_2
        expect(factories[:bar_0].create(component, :bar_0_0).m).to eq :bar_0_0
        expect(factories[:bar_0].create(component, :bar_0_1).m).to eq :bar_0_1
        expect(factories[:bar_0].create(component, :bar_0_2).m).to eq :bar_0_2
        expect(factories[:bar_0].create(component, :bar_0_3).m).to eq :bar_0_3
      end
    end

    context '#enableで対象フィーチャーの指定がある場合' do
      it '指定したフィーチャーのファクトリを生成する' do
        registry.enable(:bar_0)
        factories = registry.build_factories
        expect(factories.keys).to match([:bar_0])
        expect(factories[:bar_0].create(component, :bar_0_0).m).to eq :bar_0_0
        expect(factories[:bar_0].create(component, :bar_0_1).m).to eq :bar_0_1
        expect(factories[:bar_0].create(component, :bar_0_2).m).to eq :bar_0_2
        expect(factories[:bar_0].create(component, :bar_0_3).m).to eq :bar_0_3

        registry.enable([:foo_2, :foo_0])
        factories = registry.build_factories
        expect(factories.keys).to match([:bar_0, :foo_2, :foo_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:foo_2].create(component).m).to eq :foo_2
        expect(factories[:bar_0].create(component, :bar_0_0).m).to eq :bar_0_0
        expect(factories[:bar_0].create(component, :bar_0_1).m).to eq :bar_0_1
        expect(factories[:bar_0].create(component, :bar_0_2).m).to eq :bar_0_2
        expect(factories[:bar_0].create(component, :bar_0_3).m).to eq :bar_0_3

        registry.enable(:bar_0, :bar_0_0)
        registry.enable(:bar_0, [:bar_0_1, :bar_0_2])
        factories = registry.build_factories
        expect(factories.keys).to match([:bar_0, :foo_2, :foo_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:foo_2].create(component).m).to eq :foo_2
        expect(factories[:bar_0].create(component, :bar_0_0).m).to eq :bar_0_0
        expect(factories[:bar_0].create(component, :bar_0_1).m).to eq :bar_0_1
        expect(factories[:bar_0].create(component, :bar_0_2).m).to eq :bar_0_2
        expect(factories[:bar_0].create(component, :bar_0_3).m).to eq :bar_0
      end
    end

    context '#enable_allが呼ばれた場合' do
      it '再度全フィーチャーを対象フィーチャーにする' do
        registry.enable([:foo_0, :bar_0])
        registry.enable(:bar_0, :bar_0_0)
        factories = registry.build_factories
        expect(factories.keys).to match([:foo_0, :bar_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:bar_0].create(component, :bar_0_0).m).to eq :bar_0_0
        expect(factories[:bar_0].create(component, :bar_0_1).m).to eq :bar_0
        expect(factories[:bar_0].create(component, :bar_0_2).m).to eq :bar_0
        expect(factories[:bar_0].create(component, :bar_0_3).m).to eq :bar_0

        registry.enable_all
        factories = registry.build_factories
        expect(factories.keys).to match([:foo_0, :foo_1, :foo_2, :bar_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:foo_1].create(component).m).to eq :foo_1
        expect(factories[:foo_2].create(component).m).to eq :foo_2
        expect(factories[:bar_0].create(component, :bar_0_0).m).to eq :bar_0_0
        expect(factories[:bar_0].create(component, :bar_0_1).m).to eq :bar_0_1
        expect(factories[:bar_0].create(component, :bar_0_2).m).to eq :bar_0_2
        expect(factories[:bar_0].create(component, :bar_0_3).m).to eq :bar_0_3
      end
    end
  end

  context '同名のフィーチャーが複数回定義された場合' do
    before do
      registry.define_simple_feature(:foo_0) do
        def m; 'foo_0!'; end
      end
      registry.define_simple_feature(:foo_1) do
        def m; 'foo_1!'; end
      end
      registry.define_list_feature(:bar_0) do
        default_feature do
          def m; 'bar_0!'; end
        end
      end
      registry.define_list_feature(:bar_1) do
        default_feature do
          def m; 'bar_1'; end
        end
      end
    end

    specify '後に定義されたフィーチャーが生成される' do
      registry.define_simple_feature(:foo_0) do
        def m; 'foo_0!!'; end
      end
      registry.define_list_feature(:foo_1) do
        default_feature do
          def m; 'foo_1!!'; end
        end
      end
      registry.define_list_feature(:bar_0) do
        default_feature do
          def m; 'bar_0!!'; end
        end
      end
      registry.define_simple_feature(:bar_1) do
        def m; 'bar_1!!'; end
      end
      factories = registry.build_factories

      feature = factories[:foo_0].create(component)
      expect(feature.m).to eq 'foo_0!!'

      feature = factories[:foo_1].create(component, :foo_1)
      expect(feature.m).to eq 'foo_1!!'

      feature = factories[:bar_0].create(component, :bar_0)
      expect(feature.m).to eq 'bar_0!!'

      feature = factories[:bar_1].create(component)
      expect(feature.m).to eq 'bar_1!!'
    end
  end

  context 'フィーチャー定義時に共通コンテキストが与えられた場合' do
    let(:context) { Object.new }

    specify 'フィーチャー内で共通コンテキストを参照できる' do
      registry.define_simple_feature(:foo, context) do
      end
      registry.define_list_feature(:bar, context) do
        default_feature {}
      end
      registry.define_list_item_feature(:bar, :bar_0) do
      end
      registry.define_list_feature(:baz) do
      end
      registry.define_list_item_feature(:baz, :baz_0, context) do
      end
      factories = registry.build_factories

      feature = factories[:foo].create(component)
      expect(feature.shared_context).to be context

      feature = factories[:bar].create(component, :bar_0)
      expect(feature.shared_context).to be context

      feature = factories[:bar].create(component, :bar_1)
      expect(feature.shared_context).to be context

      feature = factories[:baz].create(component, :baz_0)
      expect(feature.shared_context).to be context
    end
  end

  context '未定義のリストフィーチャーを定義しようとした場合' do
    before do
      registry.define_simple_feature(:foo) do
      end
    end

    specify 'BuilderErrorが発生する' do
      expect {
        registry.define_list_item_feature(:foo, :foo_0)
      }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown list feature: foo'

      expect {
        registry.define_list_item_feature(:bar, :bar_0)
      }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown list feature: bar'
    end
  end

  describe '#delete' do
    before do
      [:foo, :bar, :baz].each do |feature|
        registry.define_simple_feature(feature) do
          define_method(:m) { feature }
        end
      end
      [:qux_0, :qux_1].each do |feature|
        registry.define_list_feature(feature) do
          define_default_feature do
            define_method(:m) { feature }
          end
        end
      end
      [:qux_0_0, :qux_0_1, :qux_0_2, :qux_0_3].each do |feature|
        registry.define_list_item_feature(:qux_0, feature) do
          define_method(:m) { feature }
        end
      end
      [:qux_1_0, :qux_1_1, :qux_1_2, :qux_1_3].each do |feature|
        registry.define_list_item_feature(:qux_1, feature) do
          define_method(:m) { feature }
        end
      end
    end

    context '無引数で呼び出した場合' do
      it '定義したフィーチャーを全て削除する' do
        registry.delete
        expect(registry.build_factories).to be_empty
      end
    end

    context 'フィーチャー名が与えられた場合' do
      it '指定されたフィーチャーを削除する' do
        registry.delete(:foo)
        registry.delete([:bar, :qux_0])
        registry.delete(:qux_1, :qux_1_0)
        registry.delete(:qux_1, [:qux_1_1, :qux_1_2])

        factories = registry.build_factories
        expect(factories.keys).to match([:baz, :qux_1])

        feature = factories[:baz].create(component)
        expect(feature.m).to eq :baz

        [:qux_1_0, :qux_1_1, :qux_1_2, :qux_1_3].each do |feature_name|
          feature = factories[:qux_1].create(component, feature_name)
          expect(feature.m).to eq(feature_name == :qux_1_3 ? :qux_1_3 : :qux_1)
        end
      end
    end
  end

  describe '#feature?' do
    before do
      registry.define_simple_feature(:foo_0)
      registry.define_list_feature(:bar_0)
      registry.define_list_item_feature(:bar_0, :bar_0_0)
    end

    it '定義済みフィーチャーかどうかを返す' do
      expect(registry.feature?(:foo_0)).to be true
      expect(registry.feature?(:foo_1)).to be false
      expect(registry.feature?(:bar_0)).to be true
      expect(registry.feature?(:bar_1)).to be false
      expect(registry.feature?(:bar_0, :bar_0_0)).to be true
      expect(registry.feature?(:bar_0, :bar_0_1)).to be false
      expect(registry.feature?(:bar_1, :bar_1_0)).to be false
    end
  end
end

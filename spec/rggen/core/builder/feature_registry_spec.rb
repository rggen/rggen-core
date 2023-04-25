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
        registry.define_feature(feature) do
          define_feature do
            define_method(:m) { feature }
          end
        end
      end

      [:bar_0, :bar_1, :bar_2].each do |feature|
        registry.define_simple_feature(feature) do
          define_method(:m) { feature }
        end
      end
      [:baz_0].each do |feature|
        registry.define_list_feature(feature) do
          define_default_feature { define_method(:m) { feature } }
        end
      end
      [:baz_0_0, :baz_0_1, :baz_0_2, :baz_0_3].each do |feature|
        registry.define_list_item_feature(:baz_0, feature) do
          define_method(:m) { feature }
        end
      end
    end

    context '#enableで対象フィーチャーの指定がない場合' do
      it '定義したフィーチャーすべてのファクトリを生成する' do
        factories = registry.build_factories
        expect(factories.keys).to match([:foo_0, :foo_1, :foo_2, :bar_0, :bar_1, :bar_2, :baz_0])

        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:foo_1].create(component).m).to eq :foo_1
        expect(factories[:foo_2].create(component).m).to eq :foo_2
        expect(factories[:bar_0].create(component).m).to eq :bar_0
        expect(factories[:bar_1].create(component).m).to eq :bar_1
        expect(factories[:bar_2].create(component).m).to eq :bar_2
        expect(factories[:baz_0].create(component, :baz_0_0).m).to eq :baz_0_0
        expect(factories[:baz_0].create(component, :baz_0_1).m).to eq :baz_0_1
        expect(factories[:baz_0].create(component, :baz_0_2).m).to eq :baz_0_2
        expect(factories[:baz_0].create(component, :baz_0_3).m).to eq :baz_0_3
      end
    end

    context '#enableで対象フィーチャーの指定がある場合' do
      it '指定したフィーチャーのファクトリを生成する' do
        registry.enable(:baz_0)
        factories = registry.build_factories
        expect(factories.keys).to match([:baz_0])
        expect(factories[:baz_0].create(component, :baz_0_0).m).to eq :baz_0_0
        expect(factories[:baz_0].create(component, :baz_0_1).m).to eq :baz_0_1
        expect(factories[:baz_0].create(component, :baz_0_2).m).to eq :baz_0_2
        expect(factories[:baz_0].create(component, :baz_0_3).m).to eq :baz_0_3

        registry.enable([:bar_2, :foo_0])
        factories = registry.build_factories
        expect(factories.keys).to match([:baz_0, :bar_2, :foo_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:bar_2].create(component).m).to eq :bar_2
        expect(factories[:baz_0].create(component, :baz_0_0).m).to eq :baz_0_0
        expect(factories[:baz_0].create(component, :baz_0_1).m).to eq :baz_0_1
        expect(factories[:baz_0].create(component, :baz_0_2).m).to eq :baz_0_2
        expect(factories[:baz_0].create(component, :baz_0_3).m).to eq :baz_0_3

        registry.enable(:baz_0, :baz_0_0)
        registry.enable(:baz_0, [:baz_0_1, :baz_0_2])
        factories = registry.build_factories
        expect(factories.keys).to match([:baz_0, :bar_2, :foo_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:bar_2].create(component).m).to eq :bar_2
        expect(factories[:baz_0].create(component, :baz_0_0).m).to eq :baz_0_0
        expect(factories[:baz_0].create(component, :baz_0_1).m).to eq :baz_0_1
        expect(factories[:baz_0].create(component, :baz_0_2).m).to eq :baz_0_2
        expect(factories[:baz_0].create(component, :baz_0_3).m).to eq :baz_0
      end
    end

    context '#enable_allが呼ばれた場合' do
      it '再度全フィーチャーを対象フィーチャーにする' do
        registry.enable([:foo_0, :bar_0, :baz_0])
        registry.enable(:baz_0, :baz_0_0)
        factories = registry.build_factories
        expect(factories.keys).to match([:foo_0, :bar_0, :baz_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:bar_0].create(component).m).to eq :bar_0
        expect(factories[:baz_0].create(component, :baz_0_0).m).to eq :baz_0_0
        expect(factories[:baz_0].create(component, :baz_0_1).m).to eq :baz_0
        expect(factories[:baz_0].create(component, :baz_0_2).m).to eq :baz_0
        expect(factories[:baz_0].create(component, :baz_0_3).m).to eq :baz_0

        registry.enable_all
        factories = registry.build_factories
        expect(factories.keys).to match([:foo_0, :foo_1, :foo_2, :bar_0, :bar_1, :bar_2, :baz_0])
        expect(factories[:foo_0].create(component).m).to eq :foo_0
        expect(factories[:foo_1].create(component).m).to eq :foo_1
        expect(factories[:foo_2].create(component).m).to eq :foo_2
        expect(factories[:bar_0].create(component).m).to eq :bar_0
        expect(factories[:bar_1].create(component).m).to eq :bar_1
        expect(factories[:bar_2].create(component).m).to eq :bar_2
        expect(factories[:baz_0].create(component, :baz_0_0).m).to eq :baz_0_0
        expect(factories[:baz_0].create(component, :baz_0_1).m).to eq :baz_0_1
        expect(factories[:baz_0].create(component, :baz_0_2).m).to eq :baz_0_2
        expect(factories[:baz_0].create(component, :baz_0_3).m).to eq :baz_0_3
      end
    end
  end

  context '同名のフィーチャーが複数回定義された場合' do
    before do
      registry.define_feature(:foo_0) do
        feature do
          def m; 'foo_0!'; end
        end
      end
      registry.define_feature(:foo_1) do
        feature do
          def m; 'foo_1!'; end
        end
      end
      registry.define_feature(:foo_2) do
        feature do
          def m; 'foo_2!'; end
        end
      end
      registry.define_simple_feature(:bar_0) do
        def m; 'bar_0!'; end
      end
      registry.define_simple_feature(:bar_1) do
        def m; 'bar_1!'; end
      end
      registry.define_simple_feature(:bar_2) do
        def m; 'bar_2!'; end
      end
      registry.define_list_feature(:baz_0) do
        default_feature do
          def m; 'baz_0!'; end
        end
      end
      registry.define_list_feature(:baz_1) do
        default_feature do
          def m; 'baz_1'; end
        end
      end
      registry.define_list_feature(:baz_2) do
        default_feature do
          def m; 'baz_2'; end
        end
      end
    end

    specify '後に定義されたフィーチャーが生成される' do
      registry.define_feature(:foo_0) do
        feature do
          def m; 'foo_0!!'; end
        end
      end
      registry.define_simple_feature(:foo_1) do
        def m; 'foo_1!!'; end
      end
      registry.define_list_feature(:foo_2) do
        default_feature do
          def m; 'foo_2!!'; end
        end
      end
      registry.define_simple_feature(:bar_0) do
        def m; 'bar_0!!'; end
      end
      registry.define_list_feature(:bar_1) do
        default_feature do
          def m; 'bar_1!!'; end
        end
      end
      registry.define_feature(:bar_2) do
        feature do
          def m; 'bar_2!!'; end
        end
      end
      registry.define_list_feature(:baz_0) do
        default_feature do
          def m; 'baz_0!!'; end
        end
      end
      registry.define_feature(:baz_1) do
        feature do
          def m; 'baz_1!!'; end
        end
      end
      registry.define_simple_feature(:baz_2) do
        def m; 'baz_2!!'; end
      end
      factories = registry.build_factories

      feature = factories[:foo_0].create(component)
      expect(feature.m).to eq 'foo_0!!'
      feature = factories[:foo_1].create(component)
      expect(feature.m).to eq 'foo_1!!'
      feature = factories[:foo_2].create(component, :foo_2)
      expect(feature.m).to eq 'foo_2!!'

      feature = factories[:bar_0].create(component)
      expect(feature.m).to eq 'bar_0!!'
      feature = factories[:bar_1].create(component, :bar_1)
      expect(feature.m).to eq 'bar_1!!'
      feature = factories[:bar_2].create(component)
      expect(feature.m).to eq 'bar_2!!'

      feature = factories[:baz_0].create(component, :baz_0)
      expect(feature.m).to eq 'baz_0!!'
      feature = factories[:baz_1].create(component)
      expect(feature.m).to eq 'baz_1!!'
      feature = factories[:baz_2].create(component)
      expect(feature.m).to eq 'baz_2!!'
    end
  end

  context 'フィーチャー定義時に共通コンテキストが与えられた場合' do
    let(:context) { Object.new }

    specify 'フィーチャー内で共通コンテキストを参照できる' do
      registry.define_feature(:foo, context) do
      end
      registry.define_simple_feature(:bar, context) do
      end
      registry.define_list_feature(:baz, context) do
        default_feature {}
      end
      registry.define_list_item_feature(:baz, :baz_0) do
      end
      registry.define_list_feature(:qux) do
      end
      registry.define_list_item_feature(:qux, :qux_0, context) do
      end
      factories = registry.build_factories

      feature = factories[:foo].create(component)
      expect(feature.shared_context).to be context

      feature = factories[:bar].create(component)
      expect(feature.shared_context).to be context

      feature = factories[:baz].create(component, :baz_0)
      expect(feature.shared_context).to be context

      feature = factories[:baz].create(component, :baz_1)
      expect(feature.shared_context).to be context

      feature = factories[:qux].create(component, :qux_0)
      expect(feature.shared_context).to be context
    end
  end

  context '未定義のリストフィーチャーを定義しようとした場合' do
    before do
      registry.define_feature(:foo) do
      end
      registry.define_simple_feature(:bar) do
      end
    end

    specify 'BuilderErrorが発生する' do
      expect {
        registry.define_list_item_feature(:foo, :foo_0)
      }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown list feature: foo'

      expect {
        registry.define_list_item_feature(:bar, :bar_0)
      }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown list feature: bar'

      expect {
        registry.define_list_item_feature(:baz, :baz_0)
      }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown list feature: baz'
    end
  end

  describe '#delete' do
    before do
      [:foo_0, :foo_1].each do |feature|
        registry.define_feature(feature) do
          feature { define_method(:m) { feature } }
        end
      end
      [:bar_0, :bar_1].each do |feature|
        registry.define_simple_feature(feature) do
          define_method(:m) { feature }
        end
      end
      [:baz_0, :baz_1].each do |feature|
        registry.define_list_feature(feature) do
          define_default_feature { define_method(:m) { feature } }
        end
      end
      [:baz_0_0, :baz_0_1, :baz_0_2, :baz_0_3].each do |feature|
        registry.define_list_item_feature(:baz_0, feature) do
          define_method(:m) { feature }
        end
      end
      [:baz_1_0, :baz_1_1, :baz_1_2, :baz_1_3].each do |feature|
        registry.define_list_item_feature(:baz_1, feature) do
          define_method(:m) { feature }
        end
      end
    end

    context 'フィーチャー名が与えられた場合' do
      it '指定されたフィーチャーを削除する' do
        registry.delete(:foo_0)
        registry.delete([:bar_0, :baz_0])
        registry.delete(:baz_1, :baz_1_0)
        registry.delete(:baz_1, [:baz_1_1, :baz_1_2])

        factories = registry.build_factories
        expect(factories.keys).to match([:foo_1, :bar_1, :baz_1])

        feature = factories[:foo_1].create(component)
        expect(feature.m).to eq :foo_1

        feature = factories[:bar_1].create(component)
        expect(feature.m).to eq :bar_1

        [:baz_1_0, :baz_1_1, :baz_1_2, :baz_1_3].each do |feature_name|
          feature = factories[:baz_1].create(component, feature_name)
          expect(feature.m).to eq(feature_name == :baz_1_3 ? :baz_1_3 : :baz_1)
        end
      end
    end
  end

  describe '#delete_all' do
    before do
      [:foo_0, :foo_1].each do |feature|
        registry.define_feature(feature) do
          feature { define_method(:m) { feature } }
        end
      end
      [:bar_0, :bar_1].each do |feature|
        registry.define_simple_feature(feature) do
          define_method(:m) { feature }
        end
      end
      [:baz_0, :baz_1].each do |feature|
        registry.define_list_feature(feature) do
          define_default_feature { define_method(:m) { feature } }
        end
      end
      [:baz_0_0, :baz_0_1, :baz_0_2, :baz_0_3].each do |feature|
        registry.define_list_item_feature(:baz_0, feature) do
          define_method(:m) { feature }
        end
      end
      [:baz_1_0, :baz_1_1, :baz_1_2, :baz_1_3].each do |feature|
        registry.define_list_item_feature(:baz_1, feature) do
          define_method(:m) { feature }
        end
      end
    end

    it '定義したフィーチャーを全て削除する' do
      registry.delete_all
      expect(registry.build_factories).to be_empty
    end
  end

  describe '#feature?' do
    before do
      registry.define_simple_feature(:foo_0)
      registry.define_simple_feature(:bar_0)
      registry.define_list_feature(:baz_0)
      registry.define_list_item_feature(:baz_0, :baz_0_0)
    end

    it '定義済みフィーチャーかどうかを返す' do
      expect(registry.feature?(:foo_0)).to be true
      expect(registry.feature?(:foo_1)).to be false
      expect(registry.feature?(:bar_0)).to be true
      expect(registry.feature?(:bar_1)).to be false
      expect(registry.feature?(:baz_0)).to be true
      expect(registry.feature?(:baz_1)).to be false
      expect(registry.feature?(:baz_0, :baz_0_0)).to be true
      expect(registry.feature?(:baz_0, :baz_0_1)).to be false
      expect(registry.feature?(:baz_1, :baz_1_0)).to be false
    end
  end

  describe '#enabled_features' do
    before do
      [:foo_0, :foo_1].each do |feature|
        registry.define_feature(feature) {}
      end
      [:bar_0, :bar_1].each do |feature|
        registry.define_simple_feature(feature) {}
      end
      [:baz_0].each do |feature|
        registry.define_list_feature(feature) {}
      end
      [:baz_0_0, :baz_0_1, :baz_0_2].each do |feature|
        registry.define_list_item_feature(:baz_0, feature) {}
      end
      [:baz_1].each do |feature|
        registry.define_list_feature(feature) {}
      end
      [:baz_1_0, :baz_1_1, :baz_1_2].each do |feature|
        registry.define_list_item_feature(:baz_1, feature) {}
      end
    end

    context '無引数の場合' do
      it '定義済みかつ有効になっているフィーチャーの一覧を返す' do
        expect(registry.enabled_features).to match([:foo_0, :foo_1, :bar_0, :bar_1, :baz_0, :baz_1])

        registry.enable([:bar_0, :foo_0, :baz_0])
        expect(registry.enabled_features).to match([:bar_0, :foo_0, :baz_0])

        registry.enable_all
        registry.enable([:qux_0, :qux_1])
        expect(registry.enabled_features).to be_empty
      end
    end

    context 'リスト名が与えられた場合' do
      it 'リスト内で定義済みかつ有効になっているフィーチャー名を返す' do
        expect(registry.enabled_features(:foo_0)).to be_empty
        expect(registry.enabled_features(:bar_0)).to be_empty
        expect(registry.enabled_features(:baz_0)).to match([:baz_0_0, :baz_0_1, :baz_0_2])
        expect(registry.enabled_features(:baz_1)).to match([:baz_1_0, :baz_1_1, :baz_1_2])
        expect(registry.enabled_features(:qux_0)).to be_empty

        registry.enable(:baz_0)
        expect(registry.enabled_features(:baz_0)).to match([:baz_0_0, :baz_0_1, :baz_0_2])
        expect(registry.enabled_features(:baz_1)).to be_empty

        registry.enable(:baz_0, [:baz_0_2, :baz_0_0])
        expect(registry.enabled_features(:baz_0)).to match([:baz_0_2, :baz_0_0])
      end
    end
  end
end

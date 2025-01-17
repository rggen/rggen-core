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

  def feature_body(method_name, value)
    proc { define_method(method_name) { value } }
  end

  describe 'build_factories/#enable/#enable_all' do
    before do
      [:foo_0, :foo_1, :foo_2].each do |feature|
        registry.define_feature(feature, nil, [
          proc { feature(&feature_body(:m, feature)) }
        ])
      end

      [:bar_0, :bar_1, :bar_2].each do |feature|
        registry.define_simple_feature(feature, nil, [feature_body(:m, feature)])
      end
      [:baz_0].each do |feature|
        registry.define_list_feature(feature, nil, [
          proc { default_feature(&feature_body(:m, feature)) }
        ])
      end
      [:baz_0_0, :baz_0_1, :baz_0_2, :baz_0_3].each do |feature|
        registry.define_list_item_feature(:baz_0, feature, nil, [feature_body(:m, feature)])
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

  describe '#modify_*_feature' do
    specify '定義済みフィーチャーを変更する' do
      registry.define_feature(:foo, nil, [
        proc { feature(&feature_body(:fizz, 'foo fizz')) }
      ])
      registry.modify_feature(:foo, [
        proc { feature(&feature_body(:buzz, 'foo buzz')) }
      ])

      registry.define_simple_feature(:bar, nil, [feature_body(:fizz, 'bar fizz')])
      registry.modify_simple_feature(:bar, [feature_body(:buzz, 'bar buzz')])

      registry.define_list_feature(:baz, nil, [
        proc { default_feature(&feature_body(:fizz, 'baz fizz')) }
      ])
      registry.modify_list_feature(:baz, [
        proc { default_feature(&feature_body(:buzz, 'baz buzz')) }
      ])

      registry.define_list_item_feature(:baz, :baz_0, nil, [feature_body(:fizz, 'baz_0 fizz')])
      registry.modify_list_item_feature(:baz, :baz_0, [feature_body(:buzz, 'baz_0 buzz')])

      factories = registry.build_factories

      feature = factories[:foo].create(component)
      expect(feature.fizz).to eq 'foo fizz'
      expect(feature.buzz).to eq 'foo buzz'

      feature = factories[:bar].create(component)
      expect(feature.fizz).to eq 'bar fizz'
      expect(feature.buzz).to eq 'bar buzz'

      feature = factories[:baz].create(component, :baz_0)
      expect(feature.fizz).to eq 'baz_0 fizz'
      expect(feature.buzz).to eq 'baz_0 buzz'

      feature = factories[:baz].create(component, :baz_1)
      expect(feature.fizz).to eq 'baz fizz'
      expect(feature.buzz).to eq 'baz buzz'
    end

    context '未定義のフィーチャーを指定した場合' do
      it 'BuilderErrorを起こす' do
        expect {
          registry.define_feature(:foo, nil, [])
          registry.modify_feature(:bar, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: bar'

        expect {
          registry.define_simple_feature(:foo, nil, [])
          registry.modify_feature(:foo, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: foo'

        expect {
          registry.define_list_feature(:foo, nil, [])
          registry.modify_feature(:foo, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: foo'

        expect {
          registry.define_simple_feature(:foo, nil, [])
          registry.modify_simple_feature(:bar, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: bar'

        expect {
          registry.define_feature(:foo, nil, [])
          registry.modify_simple_feature(:foo, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: foo'

        expect {
          registry.define_list_feature(:foo, nil, [])
          registry.modify_simple_feature(:foo, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: foo'

        expect {
          registry.define_list_feature(:foo, nil, [])
          registry.modify_list_feature(:bar, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: bar'

        expect {
          registry.define_feature(:foo, nil, [])
          registry.modify_list_feature(:foo, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: foo'

        expect {
          registry.define_simple_feature(:foo, nil, [])
          registry.modify_list_feature(:foo, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: foo'

        expect {
          registry.define_list_feature(:foo, nil, [])
          registry.modify_list_item_feature(:bar, :bar_0, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: bar'

        expect {
          registry.define_feature(:foo, nil, [])
          registry.modify_list_item_feature(:foo, :foo_0, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: foo'

        expect {
          registry.define_simple_feature(:foo, nil, [])
          registry.modify_list_item_feature(:foo, :foo_0, [])
        }.to raise_error RgGen::Core::BuilderError, 'unknown feature: foo'
      end
    end
  end

  context '同名のフィーチャーが複数回定義された場合' do
    before do
      registry.define_feature(:foo_0, nil, [
        proc { feature(&feature_body(:m, 'foo_0!')) }
      ])
      registry.define_feature(:foo_1, nil, [
        proc { feature(&feature_body(:m, 'foo_1!')) }
      ])
      registry.define_feature(:foo_2, nil, [
        proc { feature(&feature_body(:m, 'foo_2!')) }
      ])
      registry.define_simple_feature(:bar_0, nil, [feature_body(:m, 'bar_0!')])
      registry.define_simple_feature(:bar_1, nil, [feature_body(:m, 'bar_1!')])
      registry.define_simple_feature(:bar_2, nil, [feature_body(:m, 'bar_2!')])
      registry.define_list_feature(:baz_0, nil, [
        proc { default_feature(&feature_body(:m, 'baz_0!')) }
      ])
      registry.define_list_feature(:baz_1, nil, [
        proc { default_feature(&feature_body(:m, 'baz_1!')) }
      ])
      registry.define_list_feature(:baz_2, nil, [
        proc { default_feature(&feature_body(:m, 'baz_2!')) }
      ])
    end

    specify '後に定義されたフィーチャーが生成される' do
      registry.define_feature(:foo_0, nil, [
        proc { feature(&feature_body(:m, 'foo_0!!')) }
      ])
      registry.define_simple_feature(:foo_1, nil, [feature_body(:m, 'foo_1!!')])
      registry.define_list_feature(:foo_2, nil, [
        proc { default_feature(&feature_body(:m, 'foo_2!!')) }
      ])
      registry.define_simple_feature(:bar_0, nil, [feature_body(:m, 'bar_0!!')])
      registry.define_list_feature(:bar_1, nil, [
        proc { default_feature(&feature_body(:m, 'bar_1!!')) }
      ])
      registry.define_feature(:bar_2, nil, [
        proc { feature(&feature_body(:m, 'bar_2!!')) }
      ])
      registry.define_list_feature(:baz_0, nil, [
        proc { default_feature(&feature_body(:m, 'baz_0!!')) }
      ])
      registry.define_feature(:baz_1, nil, [
        proc { feature(&feature_body(:m, 'baz_1!!')) }
      ])
      registry.define_simple_feature(:baz_2, nil, [feature_body(:m, 'baz_2!!')])
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
      registry.define_feature(:foo, context, [])
      registry.define_simple_feature(:bar, context, [])
      registry.define_list_feature(:baz, context, [
        proc { default_feature {} }
      ])
      registry.define_list_item_feature(:baz, :baz_0, nil, [])
      registry.define_list_feature(:qux, nil, [])
      registry.define_list_item_feature(:qux, :qux_0, context, [])
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
      registry.define_feature(:foo, nil, [])
      registry.define_simple_feature(:bar, nil, [])
    end

    specify 'BuilderErrorが発生する' do
      expect {
        registry.define_list_item_feature(:foo, :foo_0, nil, [])
      }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown feature: foo'

      expect {
        registry.define_list_item_feature(:bar, :bar_0, nil, [])
      }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown feature: bar'

      expect {
        registry.define_list_item_feature(:baz, :baz_0, nil, [])
      }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown feature: baz'
    end
  end

  describe '#delete' do
    before do
      [:foo_0, :foo_1].each do |feature|
        registry.define_feature(feature, nil, [
          proc { feature(&feature_body(:m, feature)) }
        ])
      end
      [:bar_0, :bar_1].each do |feature|
        registry.define_simple_feature(feature, nil, [feature_body(:m, feature)])
      end
      [:baz_0, :baz_1].each do |feature|
        registry.define_list_feature(feature, nil, [
          proc { default_feature(&feature_body(:m, feature)) }
        ])
      end
      [:baz_0_0, :baz_0_1, :baz_0_2, :baz_0_3].each do |feature|
        registry.define_list_item_feature(:baz_0, feature, nil, [feature_body(:m, feature)])
      end
      [:baz_1_0, :baz_1_1, :baz_1_2, :baz_1_3].each do |feature|
        registry.define_list_item_feature(:baz_1, feature, nil, [feature_body(:m, feature)])
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
        registry.define_feature(feature, nil, [
          proc { feature(&feature_body(:m, feature)) }
        ])
      end
      [:bar_0, :bar_1].each do |feature|
        registry.define_simple_feature(feature, nil, [feature_body(:m, feature)])
      end
      [:baz_0, :baz_1].each do |feature|
        registry.define_list_feature(feature, nil, [
          proc { default_feature(&feature_body(:m, feature)) }
        ])
      end
      [:baz_0_0, :baz_0_1, :baz_0_2, :baz_0_3].each do |feature|
        registry.define_list_item_feature(:baz_0, feature, nil, [feature_body(:m, feature)])
      end
      [:baz_1_0, :baz_1_1, :baz_1_2, :baz_1_3].each do |feature|
        registry.define_list_item_feature(:baz_1, feature, nil, [feature_body(:m, feature)])
      end
    end

    it '定義したフィーチャーを全て削除する' do
      registry.delete_all
      expect(registry.build_factories).to be_empty
    end
  end

  describe '#feature?' do
    before do
      registry.define_simple_feature(:foo_0, nil, [])
      registry.define_simple_feature(:bar_0, nil, [])
      registry.define_list_feature(:baz_0, nil, [])
      registry.define_list_item_feature(:baz_0, :baz_0_0, nil, [])
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
        registry.define_feature(feature, nil, [])
      end
      [:bar_0, :bar_1].each do |feature|
        registry.define_simple_feature(feature, nil, [])
      end
      [:baz_0].each do |feature|
        registry.define_list_feature(feature, nil, [])
      end
      [:baz_0_0, :baz_0_1, :baz_0_2].each do |feature|
        registry.define_list_item_feature(:baz_0, feature, nil, [])
      end
      [:baz_1].each do |feature|
        registry.define_list_feature(feature, nil, [])
      end
      [:baz_1_0, :baz_1_1, :baz_1_2].each do |feature|
        registry.define_list_item_feature(:baz_1, feature, nil, [])
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

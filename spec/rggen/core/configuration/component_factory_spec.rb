# frozen_string_literal: true

RSpec.describe RgGen::Core::Configuration::ComponentFactory do
  def define_feature(feature_name)
    Class.new(RgGen::Core::Configuration::Feature) do
      property feature_name
      build { |value| instance_variable_set("@#{feature_name}", value) }
    end
  end

  let(:foo_feature) { define_feature(:foo) }
  let(:foo_feature_factory) do
    RgGen::Core::Configuration::FeatureFactory.new(:foo) { |f| f.target_feature foo_feature }
  end

  let(:bar_feature) { define_feature(:bar) }
  let(:bar_feature_factory) do
    RgGen::Core::Configuration::FeatureFactory.new(:bar) { |f| f.target_feature bar_feature }
  end

  let(:baz_feature) { define_feature(:baz) }
  let(:baz_feature_factory) do
    RgGen::Core::Configuration::FeatureFactory.new(:baz) { |f| f.target_feature baz_feature }
  end

  let(:feature_factories) do
    { foo: foo_feature_factory, bar: bar_feature_factory, baz: baz_feature_factory }
  end

  let(:factory) do
    RgGen::Core::Configuration::ComponentFactory.new('configuration', nil) do |f|
      f.root_factory
      f.target_component RgGen::Core::Configuration::Component
      f.component_factories nil => f
      f.feature_factories feature_factories
      f.loaders [RgGen::Core::Configuration::JSONLoader.new([], {})]
    end
  end

  describe '#create' do
    context '入力ファイルが与えられた場合' do
      it '入力ファイルの内容でコンフィグレーションコンポーネントの生成を行う' do
        feature_values = { foo: rand(99), bar: rand(99), baz: rand(99) }
        file = 'foo.json'
        mock_file_read(file, JSON.dump(feature_values))

        configuration = factory.create([file])
        expect(configuration).to have_attributes(feature_values)
      end
    end

    context '入力ファイルが未指定の場合' do
      it '欠損値を使ってコンフィグレーションコンポーネントの生成を行う' do
        na_value = RgGen::Core::InputBase::NAValue

        expect(foo_feature_factory)
          .to receive(:create).with(anything, equal(na_value)).and_call_original
        expect(bar_feature_factory)
          .to receive(:create).with(anything, equal(na_value)).and_call_original
        expect(baz_feature_factory)
          .to receive(:create).with(anything, equal(na_value)).and_call_original

        configuration = factory.create([])
        expect(configuration).to have_attributes(foo: be_nil, bar: be_nil, baz: be_nil)
      end
    end
  end
end

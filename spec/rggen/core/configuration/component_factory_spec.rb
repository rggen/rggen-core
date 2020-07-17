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
      f.loaders [RgGen::Core::Configuration::JSONLoader.new([])]
    end
  end

  describe '#create' do
    let(:feature_values) do
      { foo: rand(99), bar: rand(99), baz: rand(99) }
    end

    let(:file_content) { JSON.dump(feature_values) }

    let(:file) { 'foo.json' }

    before do
      allow(File).to receive(:readable?).with(file).and_return(true)
      allow(File).to receive(:binread).with(file).and_return(file_content)
    end

    it 'コンフィグレーションコンポーネントの生成と組み立てを行う' do
      configuration = factory.create([file])
      expect(configuration).to have_attributes(feature_values)
    end
  end
end

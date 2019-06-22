# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::OutputBase
  describe FeatureFactory do
    let(:configuration) do
      RgGen::Core::Configuration::Component.new(nil)
    end

    let(:register_map) do
      RgGen::Core::RegisterMap::Component.new(nil, configuration)
    end

    let(:component) do
      RgGen::Core::OutputBase::Component.new(nil, configuration, register_map)
    end

    let(:feature_factory) do
      FeatureFactory.new(:feature) { |f| f.target_feature feature }
    end

    describe '#create' do
      let(:feature) do
        Class.new(Feature) do
          class << self
            attr_accessor :observer
          end
          build { self.class.observer&.observe }
        end
      end

      it '#create_featureを呼んで、フィーチャーを生成する' do
        expect(feature_factory)
          .to receive(:create_feature)
          .with(equal(component), equal(configuration), equal(register_map))
          .and_call_original
        feature_factory.create(component, configuration, register_map)
      end

      it 'Feature#buildを呼んで、フィーチャーの組み立てを行う' do
        feature.observer = double('observer')
        expect(feature.observer).to receive(:observe)
        feature_factory.create(component, configuration, register_map)
      end
    end
  end
end

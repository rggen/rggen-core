# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Base
  describe FeatureFactory do
    let(:created_features) { [] }

    let(:foo_feature) do
      features = created_features
      Class.new(Feature) do
        define_method(:post_initialize) { features << self }
      end
    end

    let(:bar_feature) do
      features = created_features
      Class.new(Feature) do
        define_method(:post_initialize) { features << self }
      end
    end

    let(:baz_feature) do
      features = created_features
      Class.new(Feature) do
        define_method(:post_initialize) { features << self }
      end
    end

    let(:factory_class) do
      Class.new(FeatureFactory) do
        def create(component, *args, &block)
          create_feature(component, *args, &block)
        end

        def select_feature(arg)
          @target_features[arg]
        end
      end
    end

    let(:feature_name) { :feature_name }

    let(:factory) { factory_class.new(feature_name) { |f| f.target_feature foo_feature } }

    let(:component) { Component.new }

    describe "#create_feature" do
      it "対象フィーチャーを生成し、コンポーネントに追加する" do
        factory.create(component)
        expect(component.feature(feature_name)).to equal(created_features.first)
      end

      it "生成したフィーチャーオブジェクトを引数にして、与えられたブロックを実行する" do
        created_feature = nil
        factory.create(component) { |feature| created_feature = feature }
        expect(created_feature).to equal(created_features.first)
      end

      context "#target_featuresで対象フィーチャークラス群が登録されている場合" do
        before do
          factory.target_features bar_feature: bar_feature, baz_feature: baz_feature
        end

        context "#select_featureが対象フィーチャーを返す場合" do
          it "#select_featureで選択されたフィーチャーオブジェクトを生成する" do
            factory.create(component, :bar_feature)
            expect(component.feature(:feature_name)).to be_an_instance_of bar_feature
            factory.create(component, :baz_feature)
            expect(component.feature(:feature_name)).to be_an_instance_of baz_feature
          end
        end

        context "#select_featureが対象フィーチャーを返さない場合" do
          it "#target_featureで登録されたフィーチャーオブジェクトを生成する" do
            factory.create(component, :qux_feature)
            expect(component.feature(:feature_name)).to be_an_instance_of foo_feature
          end
        end
      end

      context "生成したフィーチャーオブジェクトが使用不可(Feature#available?がfalseを返す)場合" do
        before do
          foo_feature.class_eval { available? { false } }
        end

        it "コンポーネントに生成したフィーチャーを追加しない" do
          factory.create(component)
          expect(component.features).to be_empty
        end

        it "与えられたブロックを実行しない" do
          expect { |b| factory.create(component, &b) }.not_to yield_control
        end
      end
    end
  end
end

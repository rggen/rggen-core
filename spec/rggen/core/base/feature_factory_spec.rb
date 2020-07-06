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

        def target_feature_key(arg)
          arg
        end
      end
    end

    let(:feature_name) { :feature_name }

    let(:factory) { factory_class.new(feature_name) { |f| f.target_feature foo_feature } }

    let(:component) { Component.new(nil, 'component', nil) }

    describe '#create_feature' do
      it '対象フィーチャーを生成し、コンポーネントに追加する' do
        factory.create(component)
        expect(component.feature(feature_name)).to equal(created_features.first)
      end

      specify '生成されたフィーチャーは、ファクトリ生成時に指定されたフィーチャー名を持つ' do
        factory.create(component)
        feature = component.feature(feature_name)
        expect(feature.feature_name).to eq feature_name
      end

      it '生成したフィーチャーオブジェクトを引数にして、与えられたブロックを実行する' do
        created_feature = nil
        factory.create(component) { |feature| created_feature = feature }
        expect(created_feature).to equal(created_features.first)
      end

      context '#target_featuresで対象フィーチャークラス群が登録されている場合' do
        before do
          factory.target_features bar_feature: bar_feature, baz_feature: baz_feature
        end

        context '#target_feature_keyが対象フィーチャを示すキーを返す場合' do
          specify 'キーを元に、対象フィーチャークラス群から対象フィーチャーが検索される' do
            factory.create(component, :bar_feature)
            expect(component.feature(:feature_name)).to be_an_instance_of bar_feature
            factory.create(component, :baz_feature)
            expect(component.feature(:feature_name)).to be_an_instance_of baz_feature
          end

          specify '生成されたフィーチャーは、ファクトリ生成時に指定されたフィーチャー名と、検索に使われたキーを持つ' do
            factory.create(component, :bar_feature)
            feature = component.feature(:feature_name)
            expect(feature.feature_name(verbose: true)).to eq "#{feature_name}:bar_feature"
          end
        end

        context '#target_feature_keyが対象フィーチャを示すキーを返さない場合' do
          it '#target_featureで登録されたフィーチャーオブジェクトを生成する' do
            factory.create(component, :qux_feature)
            expect(component.feature(:feature_name)).to be_an_instance_of foo_feature
          end
        end
      end

      context '生成したフィーチャーオブジェクトが使用不可(Feature#available?がfalseを返す)場合' do
        before do
          foo_feature.class_eval { available? { false } }
        end

        it 'コンポーネントに生成したフィーチャーを追加しない' do
          factory.create(component)
          expect(component.features).to be_empty
        end

        it '与えられたブロックを実行しない' do
          expect { |b| factory.create(component, &b) }.not_to yield_control
        end
      end
    end
  end
end

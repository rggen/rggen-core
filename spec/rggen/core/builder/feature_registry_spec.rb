require 'spec_helper'

module RgGen::Core::Builder
  describe FeatureRegistry do
    let(:base_feature) do
      RgGen::Core::InputBase::Feature
    end

    let(:feature_factory) do
      Class.new(RgGen::Core::InputBase::FeatureFactory) do
        def create(*args); create_feature(*args); end
        def select_feature(key); @target_features[key]; end
      end
    end

    let(:registry) do
      FeatureRegistry.new(base_feature, feature_factory)
    end

    let(:component) do
      RgGen::Core::InputBase::Component.new(nil)
    end

    it "#define_simple_feature/#define_list_featureで定義されたフィーチャーを生成するファクトリーを生成する" do
      registry.define_simple_feature(nil, :foo) do
        def m; 'foo!'; end
      end
      registry.define_simple_feature(nil, :bar) do
        def m; 'bar!'; end
      end
      registry.define_list_feature(nil, :baz) do
        default_feature do
          def m; 'default baz!'; end
        end
      end
      registry.define_list_feature(nil, :baz, :baz_0) do
        def m; 'baz 0!'; end
      end
      registry.define_list_feature(nil, :baz, :baz_1) do
        def m; 'baz 1!'; end
      end
      registry.define_list_feature(nil, :baz, :baz_2) do
        def m; 'baz 2!'; end
      end

      registry.enable(:foo)
      registry.enable([:bar, :baz])
      registry.enable(:baz, :baz_0)
      registry.enable(:baz, [:baz_1, :baz_2])
      factories = registry.build_factories

      feature = factories[:foo].create(component)
      expect(feature.m).to eq 'foo!'

      feature = factories[:bar].create(component)
      expect(feature.m).to eq 'bar!'

      feature = factories[:baz].create(component, :baz_0)
      expect(feature.m).to eq 'baz 0!'

      feature = factories[:baz].create(component, :baz_1)
      expect(feature.m).to eq 'baz 1!'

      feature = factories[:baz].create(component, :baz_2)
      expect(feature.m).to eq 'baz 2!'

      feature = factories[:baz].create(component, :baz_3)
      expect(feature.m).to eq 'default baz!'
    end

    specify "#enableで指定したフィーチャーを生成できる" do
      registry.define_simple_feature(nil, :foo_0) do
        def m; 'foo_0'; end
      end
      registry.define_simple_feature(nil, :foo_1) do
        def m; 'foo_1'; end
      end
      registry.define_list_feature(nil, :bar_0) do
        default_feature do
          def m; 'bar_0'; end
        end
      end
      registry.define_list_feature(nil, :bar_1) do
        default_feature do
          def m; 'bar_1'; end
        end
      end
      registry.define_list_feature(nil, :baz) do
        default_feature do
          def m; 'baz'; end
        end
      end
      registry.define_list_feature(nil, :baz, :baz_0) do
        def m; 'baz_0'; end
      end
      registry.define_list_feature(nil, :baz, :baz_1) do
        def m; 'baz_1'; end
      end
      registry.define_list_feature(nil, :baz, :baz_2) do
        def m; 'baz_2'; end
      end

      registry.enable([:foo_0, :bar_0, :baz])
      registry.enable(:baz, [:baz_0, :baz_1])
      factories = registry.build_factories

      expect(factories.keys).to match [:foo_0, :bar_0, :baz]
      [
        [:foo_0, nil, 'foo_0'],
        [:bar_0, nil, 'bar_0'],
        [:baz, :baz_0, 'baz_0'],
        [:baz, :baz_1, 'baz_1'],
        [:baz, :baz_2, 'baz']
      ].each do |(key, arg, expectation)|
        feature = factories[key].create(component, arg)
        expect(feature.m).to eq expectation
      end
    end

    context "同名のフィーチャーが複数回定義された場合" do
      before do
        registry.define_simple_feature(nil, :foo_0) do
          def m; 'foo_0!'; end
        end
        registry.define_simple_feature(nil, :foo_1) do
          def m; 'foo_1!'; end
        end
        registry.define_list_feature(nil, :bar_0) do
          default_feature do
            def m; 'bar_0!'; end
          end
        end
        registry.define_list_feature(nil, :bar_1) do
          default_feature do
            def m; 'bar_1'; end
          end
        end
      end

      specify "後に定義されたフィーチャーが生成される" do
        registry.define_simple_feature(nil, :foo_0) do
          def m; 'foo_0!!'; end
        end
        registry.define_list_feature(nil, :foo_1) do
          default_feature do
            def m; 'foo_1!!'; end
          end
        end
        registry.define_list_feature(nil, :bar_0) do
          default_feature do
            def m; 'bar_0!!'; end
          end
        end
        registry.define_simple_feature(nil, :bar_1) do
          def m; 'bar_1!!'; end
        end

        registry.enable([:foo_0, :foo_1, :bar_0, :bar_1])
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

    context "フィーチャー定義時に共通コンテキストが与えられた場合" do
      let(:context) { Object.new }

      specify "フィーチャー内で共通コンテキストを参照できる" do
        registry.define_simple_feature(context, :foo) do
        end
        registry.define_list_feature(context, :bar) do
          default_feature {}
        end
        registry.define_list_feature(nil, :bar, :bar_0) do
        end
        registry.define_list_feature(nil, :baz) do
        end
        registry.define_list_feature(context, :baz, :baz_0) do
        end

        registry.enable([:foo, :bar, :baz])
        registry.enable(:bar, :bar_0)
        registry.enable(:baz, :baz_0)
        factories = registry.build_factories

        feature = factories[:foo].create(component)
        expect(feature.send(:shared_context)).to be context

        feature = factories[:bar].create(component, :bar_0)
        expect(feature.send(:shared_context)).to be context

        feature = factories[:bar].create(component, :bar_1)
        expect(feature.send(:shared_context)).to be context

        feature = factories[:baz].create(component, :baz_0)
        expect(feature.send(:shared_context)).to be context
      end
    end

    context "未定義のリストフィーチャーを定義しようとした場合" do
      before do
        registry.define_simple_feature(nil, :foo) do
        end
      end

      specify "BuilderErrorが発生する" do
        expect {
          registry.define_list_feature(nil, :foo, :foo_0)
        }.to raise_error RgGen::Core::BuilderError, 'unknown list feature: foo'

        expect {
          registry.define_list_feature(nil, :bar, :bar_0)
        }.to raise_error RgGen::Core::BuilderError, 'unknown list feature: bar'
      end
    end
  end
end

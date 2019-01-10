require 'spec_helper'

module RgGen::Core::Builder
  describe ComponentRegistry do
    let(:builder) { double('builder') }

    let(:registry_name) { :registry }

    def create_registry
      registry = ComponentRegistry.new(registry_name, builder)
      block_given? && yield(registry)
      registry
    end

    describe "コンポーネントの登録" do
      let(:base_component) do
        Class.new(RgGen::Core::Base::Component) do
          def all_children
            [self, *@children.flat_map(&:all_children)]
          end
        end
      end

      let(:base_factory) do
        Class.new(RgGen::Core::Base::ComponentFactory) do
          def create_component(parent, *_, &block)
            @target_component.new(parent, &block)
          end
          def create_children(component, *_)
            create_child(component)
          end
        end
      end

      specify "#register_componentで登録されたコンポーネントは、生成したファクトリで生成できる" do
        registry = create_registry do |r|
          r.register_component do
            component(base_component) do
              def m; :foo_0; end
            end
            component_factory(base_factory)
          end
          r.register_component(:foo_1) do |category|
            component(base_component) do
              define_method(:m) { category }
            end
            component_factory(base_factory)
          end
          r.register_component([:foo_2, :foo_3]) do |category|
            component(base_component) do
              define_method(:m) { category }
            end
            component_factory(base_factory)
          end
        end

        factory = registry.build_root_factory
        root_component = factory.create
        components = *root_component.all_children

        [:foo_0, :foo_1, :foo_2, :foo_3].each_with_index do |expectation, i|
          expect(components[i].level).to eq i
          expect(components[i].m).to eq expectation
        end
      end

      context "フィーチャーの登録を含む場合" do
        before do
          allow(builder).to receive(:add_feature_registry)
        end

        specify "フィーチャーレジストリがビルダーに追加される" do
          feature_registries = []

          create_registry do |r|
            r.register_component do
              component(RgGen::Core::Base::Component)
              component_factory(RgGen::Core::Base::ComponentFactory)
              base_feature(RgGen::Core::Base::Feature)
              feature_factory(RgGen::Core::Base::FeatureFactory)
              feature_registries << feature_registry
            end
            r.register_component(:foo) do
              component(RgGen::Core::Base::Component)
              component_factory(RgGen::Core::Base::ComponentFactory)
              base_feature(RgGen::Core::Base::Feature)
              feature_factory(RgGen::Core::Base::FeatureFactory)
              feature_registries << feature_registry
            end
            r.register_component([:bar, :baz]) do
              component(RgGen::Core::Base::Component)
              component_factory(RgGen::Core::Base::ComponentFactory)
              base_feature(RgGen::Core::Base::Feature)
              feature_factory(RgGen::Core::Base::FeatureFactory)
              feature_registries << feature_registry
            end
          end

          expect(builder).to have_received(:add_feature_registry).with(registry_name, nil, equal(feature_registries[0])).ordered
          expect(builder).to have_received(:add_feature_registry).with(registry_name, :foo, equal(feature_registries[1])).ordered
          expect(builder).to have_received(:add_feature_registry).with(registry_name, :bar, equal(feature_registries[2])).ordered
          expect(builder).to have_received(:add_feature_registry).with(registry_name, :baz, equal(feature_registries[3])).ordered
        end
      end
    end
  end
end

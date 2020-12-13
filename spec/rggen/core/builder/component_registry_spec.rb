# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::ComponentRegistry do
  let(:register_map_layers) do
    [:root, :register_block, :register_file, :register, :bit_field]
  end

  let(:builder) do
    double('builder').tap do |b|
      allow(b).to receive(:register_map_layers).and_return(register_map_layers)
    end
  end

  let(:component_name) { 'component' }

  let(:base_component) do
    Class.new(RgGen::Core::Base::Component) do
      def all_children
        [self, *@children.flat_map(&:all_children)]
      end
    end
  end

  let(:base_factory) do
    Class.new(RgGen::Core::Base::ComponentFactory) do
      def create_children(component, *_)
        create_child(component)
      end

      def create_children?(_component)
        !next_layer.nil?
      end

      def find_child_factory(*_)
        component_factories[next_layer]
      end

      def next_layer
        keys = component_factories.keys
        index = keys.find_index { |key| key == layer }
        keys[index + 1]
      end
    end
  end

  def create_registry
    registry = described_class.new(component_name, builder)
    block_given? && yield(registry)
    registry
  end

  describe '#register_component' do
    specify '登録したコンポーネントは、生成したファクトリで生成できる' do
      registry = create_registry do |r|
        r.register_component do
          component(base_component, base_factory)
        end
      end

      components = registry.build_factory.create.all_children
      expect(components).to all(be_instance_of(base_component))
    end

    context 'global: trueが指定された場合' do
      specify '階層を持たないコンポーネントとして登録される' do
        registry = create_registry do |r|
          r.register_component(global: true) do
            component(base_component, base_factory)
          end
        end

        components = registry.build_factory.create.all_children
        expect(components.map(&:layer)).to match([be_nil])
      end
    end

    context '階層が未指定の場合' do
      specify 'ビルダが指定するレジスタマップ階層のコンポーネントとして登録される' do
        registry = create_registry do |r|
          r.register_component do
            component(base_component, base_factory)
          end
        end

        components = registry.build_factory.create.all_children
        expect(components.map(&:layer)).to match(register_map_layers)
      end
    end

    context '階層の指定がある場合' do
      specify '指定された階層のコンポーネントとして登録される' do
        registry = create_registry do |r|
          r.register_component(:foo) do
            component(base_component, base_factory)
          end
          r.register_component([:bar, :baz]) do
            component(base_component, base_factory)
          end
        end

        components = registry.build_factory.create.all_children
        expect(components.map(&:layer)).to match([:foo, :bar, :baz])
      end
    end

    specify '生成されたコンポーネントは、レジストリと同じ名前を持つ' do
      registry = create_registry do |r|
        r.register_component(global: true) do
          component(base_component, base_factory)
        end
      end

      components = registry.build_factory.create.all_children
      expect(components[0].component_name).to eq component_name

      registry = create_registry do |r|
        r.register_component do
          component(base_component, base_factory)
        end
      end

      components = registry.build_factory.create.all_children
      expect(components[0].component_name).to eq "#{register_map_layers[0]}@#{component_name}"
      expect(components[1].component_name).to eq "#{register_map_layers[1]}@#{component_name}"
      expect(components[2].component_name).to eq "#{register_map_layers[2]}@#{component_name}"
      expect(components[3].component_name).to eq "#{register_map_layers[3]}@#{component_name}"
      expect(components[4].component_name).to eq "#{register_map_layers[4]}@#{component_name}"

      registry = create_registry do |r|
        r.register_component(:foo) do
          component(base_component, base_factory)
        end
        r.register_component([:bar, :baz]) do
          component(base_component, base_factory)
        end
      end

      components = registry.build_factory.create.all_children
      expect(components[0].component_name).to eq "foo@#{component_name}"
      expect(components[1].component_name).to eq "bar@#{component_name}"
      expect(components[2].component_name).to eq "baz@#{component_name}"
    end

    context 'フィーチャの登録を含む場合' do
      before do
        allow(builder).to receive(:add_feature_registry)
      end

      specify 'フィーチャレジストリがビルダに追加される' do
        feature_registries = []

        create_registry do |r|
          r.register_component(global: true) do
            component(
              RgGen::Core::Base::Component,
              RgGen::Core::Base::ComponentFactory
            )
            feature(
              RgGen::Core::Base::Feature,
              RgGen::Core::Base::FeatureFactory
            )
            feature_registries << feature_registry
          end

          r.register_component do
            component(
              RgGen::Core::Base::Component,
              RgGen::Core::Base::ComponentFactory
            )
            feature(
              RgGen::Core::Base::Feature,
              RgGen::Core::Base::FeatureFactory
            )
            feature_registries << feature_registry
          end

          r.register_component(:foo) do
            component(
              RgGen::Core::Base::Component,
              RgGen::Core::Base::ComponentFactory
            )
            feature(
              RgGen::Core::Base::Feature,
              RgGen::Core::Base::FeatureFactory
            )
            feature_registries << feature_registry
          end

          r.register_component([:bar, :baz]) do
            component(
              RgGen::Core::Base::Component,
              RgGen::Core::Base::ComponentFactory
            )
            feature(
              RgGen::Core::Base::Feature,
              RgGen::Core::Base::FeatureFactory
            )
            feature_registries << feature_registry
          end
        end

        expect(builder).to have_received(:add_feature_registry).with(component_name, nil, equal(feature_registries[0]))
        expect(builder).to have_received(:add_feature_registry).with(component_name, register_map_layers[0], equal(feature_registries[1]))
        expect(builder).to have_received(:add_feature_registry).with(component_name, register_map_layers[1], equal(feature_registries[2]))
        expect(builder).to have_received(:add_feature_registry).with(component_name, register_map_layers[2], equal(feature_registries[3]))
        expect(builder).to have_received(:add_feature_registry).with(component_name, register_map_layers[3], equal(feature_registries[4]))
        expect(builder).to have_received(:add_feature_registry).with(component_name, register_map_layers[4], equal(feature_registries[5]))
        expect(builder).to have_received(:add_feature_registry).with(component_name, :foo, equal(feature_registries[6]))
        expect(builder).to have_received(:add_feature_registry).with(component_name, :bar, equal(feature_registries[7]))
        expect(builder).to have_received(:add_feature_registry).with(component_name, :baz, equal(feature_registries[8]))
      end
    end
  end
end

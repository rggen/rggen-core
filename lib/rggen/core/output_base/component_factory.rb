module RgGen
  module Core
    module OutputBase
      class ComponentFactory < Base::ComponentFactory
        def create_component(parent, configuration, register_map, &block)
          target_component.new(parent, configuration, register_map, &block)
        end

        def create_features(component, configuration, register_map)
          @feature_factories.each_value do |factory|
            create_feature(component, factory, configuration, register_map)
          end
        end

        def create_children(component, configuration, register_map)
          register_map.children.each do |child|
            create_child(component, configuration, child)
          end
        end

        def finalize(component)
          component.build
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class ComponentFactory < Base::ComponentFactory
        private

        def select_actual_sources(configuration, register_map)
          [configuration, register_map]
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

        def find_child_factory(_configuration, register_map)
          component_factories[register_map.layer]
        end

        def post_build(component)
          component.pre_build
        end

        def finalize(component)
          component.build
        end
      end
    end
  end
end

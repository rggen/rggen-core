# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class ComponentFactory < InputBase::ComponentFactory
        private

        def select_actual_sources(configuration, *_)
          configuration
        end

        def create_input_data(&block)
          InputData.new(:root, valid_value_lists, &block)
        end

        def find_child_factory(_configuration, register_map)
          component_factories[register_map.layer]
        end
      end
    end
  end
end

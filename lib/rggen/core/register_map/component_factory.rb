# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class ComponentFactory < InputBase::ComponentFactory
        include RaiseError

        private

        def select_actual_sources(configuration, *_)
          configuration
        end

        def create_input_data(configuration, &block)
          InputData.new(:root, valid_value_lists, configuration, &block)
        end

        def find_child_factory(_configuration, register_map)
          component_factories[register_map.layer]
        end

        NO_CHILDREN_ERROR_MESSAGES = {
          root: 'no register blocks are given',
          register_block: 'neither register files nor registers are given',
          register_file: 'neither register files nor registers are given',
          register: 'no bit fields are given'
        }.freeze

        def raise_no_children_error(comoponent)
          error(NO_CHILDREN_ERROR_MESSAGES[comoponent.layer])
        end
      end
    end
  end
end

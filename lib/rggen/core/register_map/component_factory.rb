# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class ComponentFactory < InputBase::ComponentFactory
        private

        def create_component(parent, configuration, _, &block)
          @target_component.new(parent, configuration, &block)
        end

        def create_input_data(&block)
          RegisterMapData.new(valid_value_lists, &block)
        end
      end
    end
  end
end

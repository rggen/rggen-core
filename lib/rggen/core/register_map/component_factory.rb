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
          RegisterMapData.new(valid_value_lists, &block)
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class ComponentFactory < InputBase::ComponentFactory
        private

        def create_input_data(&block)
          InputData.new(valid_value_lists, &block)
        end
      end
    end
  end
end

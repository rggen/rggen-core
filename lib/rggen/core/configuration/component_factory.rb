# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class ComponentFactory < InputBase::ComponentFactory
        private

        def create_component(*_, &block)
          @target_component.new(&block)
        end

        def create_input_data(&block)
          InputBase::InputData.new(valid_value_lists, &block)
        end
      end
    end
  end
end

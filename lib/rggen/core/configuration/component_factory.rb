# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class ComponentFactory < InputBase::ComponentFactory
        private

        def create_input_data(*_args, &)
          InputData.new(valid_value_lists, &)
        end
      end
    end
  end
end

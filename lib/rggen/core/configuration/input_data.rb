# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class InputData < InputBase::InputData
        def initialize(valid_value_lists, &)
          super(nil, valid_value_lists, &)
        end

        undef_method :child

        private

        def raise_unknown_field_error(field_name, position)
          message = "unknown configuration field is given: #{field_name}"
          error(message, position)
        end
      end
    end
  end
end

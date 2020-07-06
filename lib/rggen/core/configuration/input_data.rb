# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class InputData < InputBase::InputData
        def initialize(valid_value_lists, &block)
          super(nil, valid_value_lists, &block)
        end

        undef_method :child
      end
    end
  end
end

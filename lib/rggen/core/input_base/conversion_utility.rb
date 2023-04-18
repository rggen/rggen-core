# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module ConversionUtility
        private

        def to_int(value, position = nil)
          v, pos =
            if value.is_a?(InputValue)
              [value.value, value.position]
            else
              [value, position]
            end
          Integer(v)
        rescue ArgumentError, TypeError
          message = yield(v)
          error message, pos
        end
      end
    end
  end
end

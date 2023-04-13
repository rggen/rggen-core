# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputValueParser
        include Utility::TypeChecker

        def initialize(exception, **_option)
          @exception = exception
        end

        private

        def split_string(string, separator, limit)
          string&.split(separator, limit)&.map(&:strip)
        end

        def error(message, position_or_input_value = nil)
          position =
            if position_or_input_value.respond_to?(:position)
              position_or_input_value.position
            else
              position_or_input_value
            end
          raise @exception.new(message, position)
        end
      end
    end
  end
end

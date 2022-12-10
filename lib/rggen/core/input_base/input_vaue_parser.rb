# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputValueParser
        include Utility::TypeChecker

        def initialize(exception)
          @exception = exception
        end

        private

        def split_string(string, separator, limit)
          string&.split(separator, limit)&.map(&:strip)
        end

        def error(message, input_value = nil)
          position = input_value.position if input_value.respond_to?(:position)
          raise @exception.new(message, position)
        end
      end
    end
  end
end

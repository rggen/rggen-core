# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class RegisterMapError < Core::RuntimeError
      end

      module RaiseError
        private

        def error_exception
          RegisterMapError
        end

        def error(message, input_value = nil)
          position = input_value.position if input_value.respond_to?(:position)
          raise RegisterMapError.new(message, position || @position)
        end
      end
    end
  end
end

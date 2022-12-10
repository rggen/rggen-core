# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class ConfigurationError < Core::RuntimeError
      end

      module RaiseError
        private

        def error_exception
          ConfigurationError
        end

        def error(message, input_value = nil)
          position = input_value.position if input_value.respond_to?(:position)
          raise ConfigurationError.new(message, position || @position)
        end
      end
    end
  end
end

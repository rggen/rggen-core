# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class ConfigurationError < InputBase::InputError
      end

      module RaiseError
        def error(message, position = nil)
          raise ConfigurationError.new(message, position || @position)
        end
      end
    end
  end
end

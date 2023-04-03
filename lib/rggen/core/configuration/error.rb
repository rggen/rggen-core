# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class ConfigurationError < Core::RuntimeError
      end

      module RaiseError
        include InputBase::Error

        private

        def error_exception
          ConfigurationError
        end
      end
    end
  end
end

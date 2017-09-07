module RgGen
  module Core
    module Configuration
      class ConfigurationError < Core::RuntimeError
      end

      module RaiseError
        def error(message)
          raise ConfigurationError.new(message)
        end
      end
    end
  end
end

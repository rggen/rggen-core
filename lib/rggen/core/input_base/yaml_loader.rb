# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module YAMLLoader
        private

        def load_yaml(file)
          yaml = File.binread(file)
          result =
            if Psych::VERSION >= '3.1.0'
              YAML.safe_load(yaml, aliases: true, filename: file)
            else
              YAML.safe_load(yaml, [], [], true, file)
            end
          symbolize_key(result)
        end

        def symbolize_key(result)
          case result
          when Hash
            result.keys.each do |key|
              result[key.to_sym] = symbolize_key(result.delete(key))
            end
          when Array
            result.map! { |value| symbolize_key(value) }
          end
          result
        end
      end
    end
  end
end

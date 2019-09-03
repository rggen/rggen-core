# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module YAMLLoader
        private

        def load_yaml(file)
          result = yaml_safe_load(File.binread(file), file)
          symbolize_key(result)
        end

        if Psych::VERSION >= '3.1.0'
          def yaml_safe_load(yaml, file)
            YAML.safe_load(
              yaml,
              whitelist_classes: [Symbol], aliases: true, filename: file
            )
          end
        else
          def yaml_safe_load(yaml, file)
            YAML.safe_load(yaml, [Symbol], [], true, file)
          end
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

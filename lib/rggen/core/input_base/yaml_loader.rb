# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module YAMLLoader
        private

        if RUBY_VERSION >= '2.6.0'
          def yaml_safe_load(yaml, file)
            YAML.safe_load(
              yaml,
              permitted_classes: [Symbol], aliases: true, filename: file,
              symbolize_names: true
            )
          end
        elsif RUBY_VERSION >= '2.5.0'
          def yaml_safe_load(yaml, file)
            YAML.safe_load(yaml, [Symbol], [], true, file, symbolize_names: true)
          end
        else
          def yaml_safe_load(yaml, file)
            reuslt = YAML.safe_load(yaml, [Symbol], [], true, file)
            symbolize_keys(reuslt)
          end

          def symbolize_keys(result)
            if result.is_a? Hash
              result.each_with_object({}) do |(key, value), hash|
                hash[key.to_sym] = symbolize_keys(value)
              end
            elsif result.is_a? Array
              result.map(&method(:symbolize_keys))
            else
              result
            end
          end
        end

        def load_yaml(file)
          yaml_safe_load(File.binread(file), file)
        end
      end
    end
  end
end

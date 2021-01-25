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
        else
          def yaml_safe_load(yaml, file)
            YAML.safe_load(yaml, [Symbol], [], true, file, symbolize_names: true)
          end
        end

        def load_yaml(file)
          yaml_safe_load(File.binread(file), file)
        end
      end
    end
  end
end

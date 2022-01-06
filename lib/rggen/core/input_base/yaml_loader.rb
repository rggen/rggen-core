# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module YAMLLoader
        private

        def load_yaml(file)
          yaml = File.binread(file)
          YAML.safe_load(
            yaml,
            permitted_classes: [Symbol], aliases: true,
            filename: file, symbolize_names: true
          )
        end
      end
    end
  end
end

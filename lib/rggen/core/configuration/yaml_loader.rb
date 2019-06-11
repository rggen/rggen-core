# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class YAMLLoader < Loader
        include HashLoader

        support_types [:yaml, :yml]

        def read_file(file)
          YAML.safe_load(
            File.binread(file), [], [], true, file, symbolize_names: true
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class YAMLLoader < Loader
        include HashLoader

        support_types [:yaml, :yml]

        def read_file(file)
          YAML.safe_load(File.binread(file), [], [], true, false)
        end
      end
    end
  end
end

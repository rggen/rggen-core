# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class YAMLLoader < Loader
        include HashLoader
        include InputBase::YAMLLoader

        support_types [:yaml, :yml]

        def read_file(file)
          load_yaml(file)
        end
      end
    end
  end
end

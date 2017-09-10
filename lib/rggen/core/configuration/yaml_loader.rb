module RgGen
  module Core
    module Configuration
      class YAMLLoader < Loader
        include HashLoader

        support_types [:yaml, :yml]

        def read_file(file)
          YAML.load(File.binread(file), file)
        end
      end
    end
  end
end

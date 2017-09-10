module RgGen
  module Core
    module Configuration
      class JSONLoader < Loader
        include HashLoader

        support_types [:json]

        def read_file(file)
          JSON.parse(File.binread(file))
        end
      end
    end
  end
end

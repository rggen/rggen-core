module RgGen
  module Core
    module Configuration
      class RubyLoader < Loader
        supported_types [:rb]

        def read_file(file)
          input_data.load_file(file)
        end
      end
    end
  end
end

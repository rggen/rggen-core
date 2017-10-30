module RgGen
  module Core
    module RegisterMap
      class RubyLoader < Loader
        support_types [:rb]

        def read_file(file)
          input_data.load_file(file)
        end
      end
    end
  end
end

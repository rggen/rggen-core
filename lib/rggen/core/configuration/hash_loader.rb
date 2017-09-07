module RgGen
  module Core
    module Configuration
      module HashLoader
        def form(read_data, file)
          input_data.values(Hash(read_data))
        rescue TypeError => e
          raise Core::LoadError.new(e.message, file)
        end
      end
    end
  end
end

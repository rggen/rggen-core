# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      module HashLoader
        private

        def format_layer_data(read_data, layer, file)
          Hash(read_data)
        rescue TypeError => e
          raise Core::LoadError.new(e.message, file)
        end
      end
    end
  end
end

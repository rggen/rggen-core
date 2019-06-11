# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module JSONLoader
        private

        def load_json(file)
          json = File.binread(file)
          JSON.parse(json, symbolize_names: true)
        end
      end
    end
  end
end

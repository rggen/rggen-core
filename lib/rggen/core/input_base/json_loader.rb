# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module JSONLoader
        private

        def read_file(file)
          JSON.load_file(file, symbolize_names: true)
        end
      end
    end
  end
end

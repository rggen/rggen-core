# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module TOMLLoader
        private

        def read_file(file)
          Tomlrb.load_file(file, symbolize_keys: true)
        end
      end
    end
  end
end

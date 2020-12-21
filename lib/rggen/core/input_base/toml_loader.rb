# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module TOMLLoader
        private

        def load_toml(file)
          toml = File.binread(file)
          Tomlrb.parse(toml, symbolize_keys: true)
        end
      end
    end
  end
end

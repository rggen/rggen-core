# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module YAMLLoader
        private

        def read_file(file)
          YPS.load_file(
            file,
            aliases: true, symbolize_names: true, freeze: true, value_class: InputValue
          )
        end
      end
    end
  end
end

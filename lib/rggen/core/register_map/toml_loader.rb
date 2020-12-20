# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class TOMLLoader < Loader
        include HashLoader
        include InputBase::TOMLLoader

        support_types [:toml]

        def read_file(file)
          load_toml(file)
        end
      end
    end
  end
end

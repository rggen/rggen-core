# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class TOMLLoader < Loader
        include HashLoader
        include InputBase::TOMLLoader

        support_types [:toml]
      end
    end
  end
end

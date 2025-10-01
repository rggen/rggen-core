# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class TOMLLoader < Loader
        include HashLoader
        include InputBase::TOMLLoader

        support_types [:toml]
      end
    end
  end
end

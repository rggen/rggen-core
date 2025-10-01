# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class YAMLLoader < Loader
        include HashLoader
        include InputBase::YAMLLoader

        support_types [:yaml, :yml]
      end
    end
  end
end

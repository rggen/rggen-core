# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class Feature < InputBase::Feature
        alias_method :configuration, :component
      end
    end
  end
end

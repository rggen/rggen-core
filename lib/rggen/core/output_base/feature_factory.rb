# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class FeatureFactory < Base::FeatureFactory
        def create(component, configuration, register_map)
          create_feature(component, configuration, register_map, &:build)
        end
      end
    end
  end
end

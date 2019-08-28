# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class FeatureFactory < Base::FeatureFactory
        include RaiseError

        def create(component, configuration, register_map)
          create_feature(component, configuration, register_map)
        end
      end
    end
  end
end

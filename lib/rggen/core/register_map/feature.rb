# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class Feature < InputBase::Feature
        include Base::FeatureLayerExtension

        private

        def configuration
          @component.configuration
        end

        def post_initialize
          define_layer_methods
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class Feature < InputBase::Feature
        include Base::FeatureLayerExtension
        include RaiseError

        private

        def configuration
          @component.configuration
        end

        def post_initialize
          define_hierarchical_accessors
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class Component < InputBase::Component
        include Base::ComponentLayerExtension

        attr_reader :configuration

        private

        def post_initialize(configuration)
          @configuration = configuration
          define_layer_methods
          layer == :bit_field && need_no_children
        end
      end
    end
  end
end

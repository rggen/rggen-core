# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class Component < InputBase::Component
        include Base::HierarchicalAccessors

        attr_reader :configuration

        private

        def post_initialize(_parent, configuration)
          @configuration = configuration
          define_hierarchical_accessors
        end
      end
    end
  end
end

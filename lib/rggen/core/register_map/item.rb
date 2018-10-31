module RgGen
  module Core
    module RegisterMap
      class Item < InputBase::Item
        include Base::HierarchicalItemAccessors

        private

        def configuration
          @component.configuration
        end

        def post_initialize
          define_hierarchical_item_accessors
        end
      end
    end
  end
end

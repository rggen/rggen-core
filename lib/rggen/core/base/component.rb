module RgGen
  module Core
    module Base
      class Component
        def initialize(parent = nil)
          @parent = parent
          @children = []
          @need_children = true
          @level = (parent && parent.level + 1) || 0
          @items = {}
          block_given? && yield(self)
        end

        attr_reader :parent
        attr_reader :children
        attr_reader :level

        def need_children?
          @need_children
        end

        def need_no_children
          @need_children = false
        end

        def add_child(child)
          return unless need_children?
          children << child
        end

        def add_item(key, item)
          @items[key] = item
        end

        def items
          @items.values
        end

        def item(key)
          @items[key]
        end
      end
    end
  end
end

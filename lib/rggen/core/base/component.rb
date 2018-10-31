module RgGen
  module Core
    module Base
      class Component
        include SingleForwardable

        def initialize(*args)
          @parent = ((args.size > 0) && args.first) || nil
          @children = []
          @need_children = true
          @level = (parent && parent.level + 1) || 0
          @items = {}
          post_initialize(*args)
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
          need_children? && (children << child)
        end

        def add_item(item)
          @items[item.item_name] = item
        end

        def items
          @items.values
        end

        def item(key)
          @items[key]
        end

        private

        def post_initialize(*argv)
        end
      end
    end
  end
end

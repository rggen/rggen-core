module RgGen
  module Core
    module InputBase
      class Component < Base::Component
        def add_item(item)
          super
          object_delegators(@items[item.item_name], *item.fields)
        end

        def fields
          @items.each_value.flat_map(&:fields)
        end

        def validate
          @items.each_value(&:validate)
          @children.each(&:validate)
        end
      end
    end
  end
end

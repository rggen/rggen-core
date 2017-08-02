module RgGen
  module Core
    module Base
      class ItemFactory
        def initialize(item_name)
          @item_name = item_name
          block_given? && yield(self)
        end

        attr_setter :target_item
        attr_setter :target_items

        def create_item(component, *args)
          select_item(*args).new(component, @item_name) do |item|
            item.available? || break
            block_given? && yield(item)
            component.add_item(item)
          end
        end

        private

        def select_item(*args)
          (@target_items && select_target_item(*args)) || @target_item
        end
      end
    end
  end
end

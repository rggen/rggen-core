module RgGen
  module Core
    module Base
      class Item
        include InternalStruct
        extend Forwardable

        def initialize(component, item_name)
          @component = component
          @item_name = item_name
          post_initialize
          block_given? && yield(self)
        end

        attr_reader :component
        attr_reader :item_name

        class << self
          private

          def define_helpers(&body)
            singleton_class.class_exec(&body)
          end

          def available?(&body)
            define_method(:available?, &body)
          end
        end

        available? { true }

        private

        def post_initialize
        end
      end
    end
  end
end

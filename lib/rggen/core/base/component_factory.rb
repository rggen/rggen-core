module RgGen
  module Core
    module Base
      class ComponentFactory
        def initialize
          @root_factory = false
          block_given? && yield(self)
        end

        attr_setter :target_component
        attr_setter :item_factories
        attr_setter :child_factory

        def root_factory
          @root_factory = true
        end

        def create(*args)
          parent = (child_factory? && args.first) || nil
          sources = preprocess((child_factory? && args.from(1)) || args)
          create_component(parent, *sources) do |component|
            create_items? && create_items(component, *sources)
            child_factory? && parent.add_child(component)
            create_children?(component) && create_children(component, *sources)
            root_factory? && finalize(component)
          end
        end

        private

        def root_factory?
          @root_factory
        end

        def child_factory?
          !@root_factory
        end

        def create_items?
          @item_factories
        end

        def create_children?(component)
          @child_factory && component.need_children?
        end

        def preprocess(args)
          args
        end

        def finalize(component)
        end

        def create_item(component, factory, *args)
          factory.create(component, *args)
        end

        def create_child(component, *args)
          @child_factory.create(component, *args)
        end
      end
    end
  end
end

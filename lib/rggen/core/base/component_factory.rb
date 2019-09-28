# frozen_string_literal: true

module RgGen
  module Core
    module Base
      class ComponentFactory
        def initialize(component_name)
          @component_name = component_name
          @root_factory = false
          block_given? && yield(self)
        end

        attr_setter :target_component
        attr_setter :feature_factories
        attr_setter :child_factory

        def root_factory
          @root_factory = true
        end

        def create(*args)
          parent, sources =
            if root_factory?
              [nil, preprocess(args)]
            else
              [args.first, preprocess(args[1..-1])]
            end
          create_component(parent, sources) do |component|
            build_component(parent, component, sources)
            root_factory? && finalize(component)
          end
        end

        private

        def root_factory?
          @root_factory
        end

        def create_component(parent, sources, &block)
          actual_sources = Array(select_actual_sources(*sources))
          @target_component
            .new(@component_name, parent, *actual_sources, &block)
        end

        def select_actual_sources(*sources)
        end

        def build_component(parent, component, sources)
          do_create_features(component, sources)
          do_create_children(component, sources)
          post_build(component)
          parent&.add_child(component)
        end

        def do_create_features(component, sources)
          return unless create_features?
          create_features(component, *sources)
        end

        def create_features?
          @feature_factories
        end

        def do_create_children(component, sources)
          return unless create_children?(component)
          create_children(component, *sources)
        end

        def create_children?(component)
          @child_factory && component.need_children?
        end

        def preprocess(args)
          args
        end

        def post_build(_component)
        end

        def finalize(_component)
        end

        def create_feature(component, factory, *args)
          factory.create(component, *args)
        end

        def create_child(component, *args)
          @child_factory.create(component, *args)
        end
      end
    end
  end
end

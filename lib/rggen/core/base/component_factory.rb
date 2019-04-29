# frozen_string_literal: true

module RgGen
  module Core
    module Base
      class ComponentFactory
        def initialize
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
          parent = root_factory? ? nil : args.first
          sources = preprocess((root_factory? && args) || args[1..-1])
          create_component(parent, *sources) do |component|
            call_build_hook(:before, component)
            build_component(parent, component, sources)
            call_build_hook(:after, component)
          end
        end

        def build_hook(phase, &hook)
          (@build_hooks ||= {})[phase] = hook
        end

        private

        def root_factory?
          @root_factory
        end

        def build_component(parent, component, sources)
          do_create_features(component, sources)
          parent&.add_child(component)
          do_create_children(component, sources)
          finalize(component) if root_factory?
        end

        def do_create_features(component, sources)
          return unless create_features?
          create_features(component, *sources)
          post_create_features(component)
        end

        def create_features?
          @feature_factories
        end

        def post_create_features(_component)
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

        def finalize(component)
        end

        def create_feature(component, factory, *args)
          factory.create(component, *args)
        end

        def create_child(component, *args)
          @child_factory.create(component, *args)
        end

        def call_build_hook(phase, component)
          return unless @build_hooks
          return unless @build_hooks.key?(phase)
          @build_hooks[phase].call(component)
        end
      end
    end
  end
end

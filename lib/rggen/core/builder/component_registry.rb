# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class ComponentRegistry
        def initialize(component_name, builder)
          @component_name = component_name
          @builder = builder
          @entries = []
        end

        def register_component(categories = nil, &block)
          if categories
            Array(categories).each do |category|
              @entries << create_new_entry(category, block)
            end
          else
            @entries << create_new_entry(nil, block)
          end
        end

        def build_factory
          factories = @entries.map(&:build_factory)
          factories.each_cons(2) { |(f0, f1)| f0.child_factory(f1) }
          root_factory = factories.first
          root_factory.root_factory
          root_factory
        end

        private

        def create_new_entry(category, block)
          entry = ComponentEntry.new(@component_name)
          Docile.dsl_eval(entry, category, &block)
          add_feature_registry(category, entry.feature_registry)
          entry
        end

        def add_feature_registry(category, feature_registry)
          feature_registry || return
          @builder
            .add_feature_registry(@component_name, category, feature_registry)
        end
      end
    end
  end
end

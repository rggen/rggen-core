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

        def register_component(layers = nil, &block)
          Array(layers || @builder.register_map_layers).each do |layer|
            @entries << create_new_entry(layer, &block)
          end
        end

        def register_global_component(&block)
          @entries << create_new_entry(nil, &block)
        end

        def build_factory
          build_factories.first.tap(&:root_factory)
        end

        private

        def create_new_entry(layer, &block)
          entry = ComponentEntry.new(@component_name, layer)
          Docile.dsl_eval(entry, layer, &block)
          add_feature_registry(layer, entry.feature_registry)
          entry
        end

        def add_feature_registry(layer, feature_registry)
          feature_registry &&
            @builder.add_feature_registry(@component_name, layer, feature_registry)
        end

        def build_factories
          factories =
            @entries
              .map(&:build_factory)
              .map { |f| [f.layer, f] }.to_h
          factories.each_value { |f| f.component_factories factories }
          factories.values
        end
      end
    end
  end
end

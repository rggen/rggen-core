# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Builder
        extend Forwardable

        def initialize
          initialize_component_registries
          initialize_layers
          @plugin_manager = PluginManager.new(self)
        end

        attr_reader :plugin_manager

        def input_component_registry(name, &body)
          component_registry(:input, name, &body)
        end

        def output_component_registry(name, &body)
          component_registry(:output, name, &body)
        end

        [
          :register_loader, :register_loaders,
          :setup_loader, :define_value_extractor
        ].each do |method_name|
          define_method(method_name) do |component, *args, &block|
            @component_registries[:input][component].__send__(__method__, *args, &block)
          end
        end

        def register_map_layers
          REGISTER_MAP_LAYERS
        end

        def add_feature_registry(name, target_layer, registry)
          target_layers =
            if target_layer
              Array(@layers[target_layer])
            else
              @layers.values
            end
          target_layers
            .each { |layer| layer.add_feature_registry(name, registry) }
        end

        [
          :define_simple_feature,
          :define_list_feature,
          :define_list_item_feature
        ].each do |method_name|
          define_method(method_name) do |layer, *args, &body|
            @layers[layer].__send__(__method__, *args, &body)
          end
        end

        def enable(layer, *args)
          @layers[layer].enable(*args)
        end

        def disable_all
          @layers.each_value(&:disable)
        end

        def disable(layer, *args)
          @layers.key?(layer) && @layers[layer].disable(*args)
        end

        def build_factory(type, component)
          @component_registries[type][component].build_factory
        end

        def build_factories(type, targets)
          registries =
            if targets.empty?
              @component_registries[type]
            else
              @component_registries[type].slice(*targets)
            end
          registries.each_value.map(&:build_factory)
        end

        def delete(layer, *args)
          @layers.key?(layer) && @layers[layer].delete(*args)
        end

        def register_input_components
          Configuration.setup(self)
          RegisterMap.setup(self)
        end

        def_delegator :plugin_manager, :load_plugin
        def_delegator :plugin_manager, :load_plugins
        def_delegator :plugin_manager, :setup_plugin

        private

        def initialize_component_registries
          @component_registries = {}
          [:input, :output].each do |type|
            @component_registries[type] = Hash.new do |_, component_name|
              raise BuilderError.new("unknown component: #{component_name}")
            end
          end
        end

        REGISTER_MAP_LAYERS = [
          :root, :register_block, :register_file, :register, :bit_field
        ].freeze

        ALL_LAYERS = [
          :global, *REGISTER_MAP_LAYERS
        ].freeze

        def initialize_layers
          @layers = Hash.new do |_, layer_name|
            raise BuilderError.new("unknown layer: #{layer_name}")
          end
          ALL_LAYERS.each { |layer| @layers[layer] = Layer.new(layer) }
        end

        COMPONENT_REGISTRIES = {
          input: InputComponentRegistry, output: OutputComponentRegistry
        }.freeze

        def component_registry(type, name, &body)
          registries = @component_registries[type]
          registries.key?(name) ||
            (registries[name] = COMPONENT_REGISTRIES[type].new(name, self))
          body && Docile.dsl_eval(registries[name], &body) || registries[name]
        end
      end
    end
  end
end

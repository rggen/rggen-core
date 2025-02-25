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

        def input_component_registry(name, &)
          component_registry(:input, name, &)
        end

        def output_component_registry(name, &)
          component_registry(:output, name, &)
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
          :define_feature,
          :define_simple_feature,
          :define_list_feature,
          :define_list_item_feature,
          :modify_feature,
          :modify_simple_feature,
          :modify_list_feature,
          :modify_list_item_feature
        ].each do |method_name|
          define_method(method_name) do |layer, *args, &body|
            @layers[layer].__send__(__method__, *args, &body)
          end
        end

        def enable(layer, *args)
          @layers[layer].enable(*args)
        end

        def enable_all
          @layers.each_value(&:enable_all)
        end

        def build_factory(type, component)
          @component_registries[type][component].build_factory
        end

        def build_factories(type, targets)
          registries =
            if targets.empty?
              @component_registries[type]
            else
              collect_component_factories(type, targets)
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
        def_delegator :plugin_manager, :update_plugin

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

        def collect_component_factories(type, targets)
          unknown_components = targets - @component_registries[type].keys
          unknown_components.empty? ||
            (raise BuilderError.new("unknown component: #{unknown_components.first}"))

          @component_registries[type].slice(*targets)
        end
      end
    end
  end
end

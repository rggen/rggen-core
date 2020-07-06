# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Builder
        def initialize
          initialize_component_registries
          initialize_layers
          @plugins = Plugins.new
        end

        attr_reader :plugins

        def input_component_registry(name, &body)
          component_registry(:input, name, body)
        end

        def output_component_registry(name, &body)
          component_registry(:output, name, body)
        end

        def register_loader(component, loader)
          @component_registries[:input][component].register_loader(loader)
        end

        def register_loaders(component, loaders)
          @component_registries[:input][component].register_loaders(loaders)
        end

        def define_loader(component, &body)
          @component_registries[:input][component].define_loader(&body)
        end

        def add_feature_registry(name, target_layer, registry)
          target_layers =
            if target_layer
              Array(@layers[target_layer])
            else
              @layers.values
            end
          target_layers.each do |layer|
            layer.add_feature_registry(name, registry)
          end
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
              @component_registries[type]
                .select { |name, _| targets.include?(name) }
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

        def setup(name, module_or_version = nil, &block)
          plugins.add(name, module_or_version, &block)
        end

        def activate_plugins(**options)
          plugins.activate(self, **options)
        end

        def load_setup_file(file, activation = true)
          (file.nil? || file.empty?) &&
            (raise Core::LoadError.new('no setup file is given'))
          File.readable?(file) ||
            (raise Core::LoadError.new("cannot load such setup file: #{file}"))
          RgGen.builder(self)
          load(file)
          activation && activate_plugins
        end

        private

        def initialize_component_registries
          @component_registries = {}
          [:input, :output].each do |type|
            @component_registries[type] = Hash.new do |_, component_name|
              raise BuilderError.new("unknown component: #{component_name}")
            end
          end
        end

        def initialize_layers
          @layers = Hash.new do |_, layer_name|
            raise BuilderError.new("unknown layer: #{layer_name}")
          end
          [
            :global, :root, :register_block, :register_file, :register, :bit_field
          ].each do |layer|
            @layers[layer] = Layer.new(layer)
          end
        end

        COMPONENT_REGISTRIES = {
          input: InputComponentRegistry, output: OutputComponentRegistry
        }.freeze

        def component_registry(type, name, body)
          registries = @component_registries[type]
          klass = COMPONENT_REGISTRIES[type]
          registries.key?(name) || (registries[name] = klass.new(name, self))
          Docile.dsl_eval(registries[name], &body)
        end
      end
    end
  end
end

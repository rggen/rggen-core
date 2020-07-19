# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class InputComponentRegistry < ComponentRegistry
        def initialize(name, builder)
          super
          @loader_registries = {}
        end

        def register_loader(loader_type, loader)
          loader_registry(loader_type).register_loader(loader)
        end

        def register_loaders(loader_type, loaders)
          loader_registry(loader_type).register_loaders(loaders)
        end

        def define_value_extractor(loader_type, layers_or_value, value = nil, &body)
          layers, value =
            if value
              [layers_or_value, value]
            else
              [nil, layers_or_value]
            end
          loader_registry(loader_type).define_value_extractor(layers, value, &body)
        end

        def ignore_value(loader_type, layers_or_value, value = nil)
          layers, value =
            if value
              [layers_or_value, value]
            else
              [nil, layers_or_value]
            end
          loader_registry(loader_type).ignore_value(layers, value)
        end

        def ignore_values(loader_type, layers_or_values, values = nil)
          layers, values =
            if values
              [layers_or_values, values]
            else
              [nil, layers_or_values]
            end
          loader_registry(loader_type).ignore_values(layers, values)
        end

        def build_factory
          factory = super
          factory.loaders(build_loaders)
          factory
        end

        private

        def loader_registry(loader_type)
          @loader_registries[loader_type] ||= LoaderRegistry.new
        end

        def build_loaders
          @loader_registries.values.flat_map(&:create_loaders)
        end
      end
    end
  end
end

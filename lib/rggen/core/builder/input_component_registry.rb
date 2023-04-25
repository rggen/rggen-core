# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class InputComponentRegistry < ComponentRegistry
        def initialize(name, builder)
          super
          @loader_registries = Hash.new do |h, k|
            h[k] = LoaderRegistry.new
          end
        end

        def register_loader(loader_type, loader)
          @loader_registries[loader_type].register_loader(loader)
        end

        def register_loaders(loader_type, loaders)
          @loader_registries[loader_type].register_loaders(loaders)
        end

        def setup_loader(loader_type)
          block_given? && yield(@loader_registries[loader_type])
        end

        def define_value_extractor(loader_type, layers = nil, value, &body)
          @loader_registries[loader_type]
            .define_value_extractor(layers, value, &body)
        end

        def build_factory
          factory = super
          factory.loaders(build_loaders)
          factory
        end

        private

        def build_loaders
          @loader_registries.values.flat_map(&:create_loaders)
        end
      end
    end
  end
end

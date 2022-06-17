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

        def setup_loader(loader_type)
          block_given? && yield(@loader_registries[loader_type])
        end

        def define_value_extractor(loader_type, layers_or_value, value = nil, &body)
          @loader_registries[loader_type]
            .define_value_extractor(layers_or_value, value, &body)
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

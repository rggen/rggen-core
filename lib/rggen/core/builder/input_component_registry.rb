# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class InputComponentRegistry < ComponentRegistry
        def initialize(name, builder)
          super
          @loaders = []
        end

        def register_loader(loader)
          @loaders << loader
        end

        def register_loaders(loaders)
          @loaders.concat(Array(loaders))
        end

        def build_factory
          factory = super
          factory.loaders(build_loaders)
          factory
        end

        private

        def build_loaders
          @loaders.map { |loader| loader.new([], {}) }
        end
      end
    end
  end
end

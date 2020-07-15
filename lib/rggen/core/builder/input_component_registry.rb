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
          factory.loaders(@loaders.map(&:new))
          factory
        end
      end
    end
  end
end

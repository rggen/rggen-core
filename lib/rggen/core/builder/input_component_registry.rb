module RgGen
  module Core
    module Builder
      class InputComponentRegistry < ComponentRegistry
        def initialize(name, builder)
          super
          @loaders = []
        end

        attr_setter :base_loader

        def register_loader(loader)
          @loaders << loader
        end

        def define_loader(&body)
          loader = Class.new(@base_loader, &body)
          register_loader(loader)
        end

        def build_root_factory
          factory = super
          factory.loaders(@loaders)
          factory
        end
      end
    end
  end
end
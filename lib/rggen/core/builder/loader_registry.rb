# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class LoaderRegistry
        def initialize
          @loaders = []
          @extractors = []
          @ignore_values = {}
        end

        def register_loader(loader)
          @loaders << loader
        end

        def register_loaders(loaders)
          @loaders.concat(Array(loaders))
        end

        def define_value_extractor(layers = nil, value, &)
          @extractors << create_extractor(layers, value, &)
        end

        def ignore_value(layers = nil, value)
          ignore_values(layers, [value])
        end

        def ignore_values(layers = nil, values)
          [layers].flatten.each do |layer|
            (@ignore_values[layer] ||= []).concat(Array(values))
          end
        end

        def create_loaders
          @loaders.map { |loader| loader.new(@extractors, @ignore_values) }
        end

        private

        def create_extractor(layers, value, &)
          Class.new(Core::InputBase::InputValueExtractor, &).new(layers, value)
        end
      end
    end
  end
end

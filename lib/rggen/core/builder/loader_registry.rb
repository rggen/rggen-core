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

        def define_value_extractor(layers_or_value, value = nil, &)
          value, layers = [value, layers_or_value].compact
          @extractors << create_extractor(layers, value, &)
        end

        def ignore_values(layers_or_values, values = nil)
          values, layers = [values, layers_or_values].compact
          [layers].flatten.each do |layer|
            (@ignore_values[layer] ||= []).concat(Array(values))
          end
        end

        alias_method :ignore_value, :ignore_values

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

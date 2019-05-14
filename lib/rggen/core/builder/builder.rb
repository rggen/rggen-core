# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Builder
        def initialize
          initialize_component_registries
          initialize_categories
        end

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

        def add_feature_registry(name, target_category, registry)
          target_categories =
            if target_category
              Array(@categories[target_category])
            else
              @categories.values
            end
          target_categories.each do |category|
            category.add_feature_registry(name, registry)
          end
        end

        [
          :define_simple_feature,
          :define_list_feature,
          :define_list_item_feature
        ].each do |method_name|
          define_method(method_name) do |category, *args, &body|
            @categories[category].__send__(__method__, *args, &body)
          end
        end

        def enable(category, *args)
          @categories[category].enable(*args)
        end

        def disable_all
          @categories.each_value(&:disable)
        end

        def disable(category, *args)
          @categories.key?(category) && @categories[category].disable(*args)
        end

        def build_factory(type, component)
          @component_registries[type][component].build_factory
        end

        def build_factories(type, exceptions)
          @component_registries[type]
            .reject { |name, _| exceptions.include?(name) }
            .map { |_, registry| registry.build_factory }
        end

        def delete(category, *args)
          @categories.key?(category) && @categories[category].delete(*args)
        end

        def register_input_components
          Configuration.setup(self)
          RegisterMap.setup(self)
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

        def initialize_categories
          @categories = Hash.new do |_, category_name|
            raise BuilderError.new("unknown category: #{category_name}")
          end
          [
            :global, :register_map, :register_block, :register, :bit_field
          ].each do |category|
            @categories[category] = Category.new(category)
          end
        end

        COMPONENT_REGISTRIES = {
          input: InputComponentRegistry, output: OutputComponentRegistry
        }

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

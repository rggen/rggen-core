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

        def delete(category, *args)
          @categories.key?(category) && @categories[category].delete(*args)
        end

        def register_input_components
          Configuration.setup(self)
          RegisterMap.setup(self)
        end

        def setup(library_name, library_module)
          library_versions[library_name] =
            if library_module.const_defined?(:VERSION)
              library_module.const_get(:VERSION)
            elsif library_module.respond_to?(:version)
              library_module.version
            else
              '0.0.0'
            end
          library_module.setup(self)
        end

        def library_versions
          @library_versions ||= {}
        end

        def load_setup_file(file)
          (file.nil? || file.empty?) &&
            (raise Core::LoadError.new('no setup file is given'))
          File.readable?(file) ||
            (raise Core::LoadError.new("cannot load such setup file: #{file}"))
          RgGen.builder(self)
          load(file)
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

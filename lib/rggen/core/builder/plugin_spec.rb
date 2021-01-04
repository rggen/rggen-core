# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class PluginSpec
        def initialize(name, plugin_module)
          @name = name
          @plugin_module = plugin_module
          @component_registrations = []
          @loader_registrations = []
          @files = []
        end

        def version(value = nil)
          @version = value if value
          version_value
        end

        def version_info
          "#{@name} #{version}"
        end

        def register_component(component, layers = nil, &body)
          @component_registrations << [component, layers, body]
        end

        def register_loader(component, loader_type, loader)
          @loader_registrations << [component, loader_type, loader]
        end

        def register_loaders(component, loader_type, loaders)
          Array(loaders)
            .each { |loader| register_loader(component, loader_type, loader) }
        end

        def register_files(files)
          root = File.dirname(caller_locations(1, 1).first.path)
          files.each { |file| @files << File.join(root, file) }
        end

        alias_method :files, :register_files

        def activate(builder)
          activate_components(builder)
          activate_loaders(builder)
          load_files
        end

        private

        DEFAULT_VERSION = '0.0.0'

        def version_value
          @version || const_version || DEFAULT_VERSION
        end

        def const_version
          @plugin_module.const_defined?(:VERSION) &&
            @plugin_module.const_get(:VERSION)
        end

        def activate_components(builder)
          @component_registrations.each do |component, layers, body|
            builder
              .output_component_registry(component)
              .register_component(layers, &body)
          end
        end

        def activate_loaders(builder)
          @loader_registrations.each do |component, loader_type, loader|
            builder.register_loader(component, loader_type, loader)
          end
        end

        def load_files
          @files.each(&method(:require))
        end
      end
    end
  end
end

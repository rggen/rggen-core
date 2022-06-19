# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class PluginSpec
        def initialize(name)
          @name = name
          @component_registrations = []
          @loader_registrations = []
          @files = []
          block_given? && yield(self)
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

        def setup_loader(component, loader_type, &body)
          @loader_registrations << [component, loader_type, body]
        end

        def register_files(files)
          root = File.dirname(caller_locations(1, 1).first.path)
          files.each { |file| @files << File.join(root, file) }
        end

        alias_method :files, :register_files

        def addtional_setup(&body)
          @addtional_setup = body
        end

        def activate(builder)
          activate_components(builder)
          activate_loaders(builder)
          load_files
          @addtional_setup&.call(builder)
        end

        private

        DEFAULT_VERSION = '0.0.0'

        def version_value
          @version || DEFAULT_VERSION
        end

        def activate_components(builder)
          @component_registrations.each do |component, layers, body|
            builder
              .output_component_registry(component)
              .register_component(layers, &body)
          end
        end

        def activate_loaders(builder)
          @loader_registrations.each do |component, loader_type, body|
            builder
              .input_component_registry(component)
              .setup_loader(loader_type, &body)
          end
        end

        def load_files
          @files.each(&method(:require))
        end
      end
    end
  end
end

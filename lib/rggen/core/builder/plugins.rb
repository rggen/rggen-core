# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Plugin
        def initialize(name, plugin_module, block)
          @name = name
          @version = extract_version(plugin_module)
          @plugin_module = plugin_module
          @block = block
        end

        attr_reader :name
        attr_reader :version

        def default_setup(builder)
          @plugin_module.respond_to?(:default_setup) &&
            @plugin_module.default_setup(builder)
        end

        def optional_setup(builder)
          @block && @plugin_module.instance_exec(builder, &@block)
        end

        private

        def extract_version(plugin_module)
          if plugin_module.const_defined?(:VERSION)
            plugin_module.const_get(:VERSION)
          elsif plugin_module.respond_to?(:version)
            plugin_module.version
          else
            '0.0.0'
          end
        end
      end

      class Plugins
        def initialize
          @plugins = []
        end

        def add(name, plugin_module, block)
          @plugins << Plugin.new(name, plugin_module, block)
        end

        def activate(builder)
          @plugins.each { |plugin| plugin.default_setup(builder) }
          @plugins.each { |plugin| plugin.optional_setup(builder) }
        end

        def plugin_versions
          @plugins.map { |plugin| [plugin.name, plugin.version] }.to_h
        end
      end
    end
  end
end

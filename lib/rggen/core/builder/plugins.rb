# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Plugin
        DEFAULT_PLUGIN_VERSION = '0.0.0'

        def initialize(name, module_or_version, &block)
          @name = name
          @block = block
          @version, @plugin_module =
            if module_or_version.is_a?(Module)
              [extract_version(module_or_version), module_or_version]
            else
              [module_or_version || DEFAULT_PLUGIN_VERSION]
            end
        end

        attr_reader :name
        attr_reader :version

        def default_setup(builder)
          @plugin_module &&
            begin
              @plugin_module.respond_to?(:default_setup) &&
                @plugin_module.default_setup(builder)
            end
        end

        def optional_setup(builder)
          @block &&
            if @plugin_module
              @plugin_module.instance_exec(builder, &@block)
            else
              @block.call(builder)
            end
        end

        def version_info
          "#{name} #{version}"
        end

        private

        def extract_version(plugin_module)
          if plugin_module.const_defined?(:VERSION)
            plugin_module.const_get(:VERSION)
          elsif plugin_module.respond_to?(:version)
            plugin_module.version
          else
            DEFAULT_PLUGIN_VERSION
          end
        end
      end

      class Plugins
        def initialize
          @plugins = []
        end

        def add(name, module_or_version, &block)
          @plugins << Plugin.new(name, module_or_version, &block)
        end

        def activate(builder)
          @plugins.each { |plugin| plugin.default_setup(builder) }
          @plugins.each { |plugin| plugin.optional_setup(builder) }
        end

        def version_info
          @plugins.map(&:version_info)
        end
      end
    end
  end
end

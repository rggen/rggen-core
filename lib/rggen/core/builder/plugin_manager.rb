# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Plugin
        DEFAULT_PLUGIN_VERSION = '0.0.0'

        def initialize(name, plugin_module, &block)
          @name = name
          @plugin_module = plugin_module
          @block = block
        end

        def default_setup(builder)
          @plugin_module.respond_to?(:default_setup) &&
            @plugin_module.default_setup(builder)
        end

        def optional_setup(builder)
          @block && @plugin_module.instance_exec(builder, &@block)
        end

        def version
          if @plugin_module.const_defined?(:VERSION)
            @plugin_module.const_get(:VERSION)
          elsif @plugin_module.respond_to?(:version)
            @plugin_module.version
          else
            DEFAULT_PLUGIN_VERSION
          end
        end

        def version_info
          "#{@name} #{version}"
        end
      end

      class PluginManager
        def initialize(builder)
          @builder = builder
          @plugins = []
        end

        def load_plugin(setup_path_or_name)
          setup_path_or_name = setup_path_or_name.to_s.strip
          setup_path =
            if setup_file_directly_given?(setup_path_or_name)
              setup_path_or_name
            else
              get_setup_path(setup_path_or_name)
            end
          read_setup_file(setup_path, setup_path_or_name)
        end

        def load_plugins(plugins, no_default_plugins, activation = true)
          RgGen.builder(@builder)
          merge_plugins(plugins, no_default_plugins)
            .each { |plugin| load_plugin(*plugin) }
          activation && activate_plugins
        end

        def setup(name, plugin_module, &block)
          @plugins << Plugin.new(name, plugin_module, &block)
        end

        def activate_plugins(**options)
          options[:no_default_setup] ||
            @plugins.each { |plugin| plugin.default_setup(@builder) }
          options[:no_optional_setup] ||
            @plugins.each { |plugin| plugin.optional_setup(@builder) }
        end

        def version_info
          @plugins.map(&:version_info)
        end

        private

        def setup_file_directly_given?(setup_path_or_name)
          File.ext(setup_path_or_name) == 'rb' ||
            File.basename(setup_path_or_name, '.*') == 'setup'
        end

        def get_setup_path(name)
          base, sub_directory = name.split('/', 2)
          base = base.sub(/^rggen[-_]/, '').tr('-', '_')
          File.join(*[
            'rggen', base, sub_directory || '', 'setup'
          ].reject(&:empty?))
        end

        def read_setup_file(setup_path, setup_path_or_name)
          require setup_path
        rescue ::LoadError
          raise Core::LoadError.new([
            "cannot load such plugin: #{setup_path_or_name}",
            setup_path_or_name != setup_path && " (#{setup_path})" || ''
          ].join)
        end

        def merge_plugins(plugins, no_default_plugins)
          [
            *default_plugins(no_default_plugins),
            *plugins_from_env,
            *plugins
          ]
        end

        def default_plugins(no_default_plugins)
          return nil if no_default_plugins || ENV.key?('RGGEN_NO_DEFAULT_PLUGINS')

          require 'rggen/default_plugins'
          ::RgGen::DEFAULT_PLUGINS
        rescue ::LoadError
          nil
        end

        def plugins_from_env
          ENV['RGGEN_PLUGINS']&.split(':')
        end
      end
    end
  end
end

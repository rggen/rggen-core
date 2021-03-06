# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class PluginRegistry
        def initialize(plugin_module, &block)
          @plugin_module = plugin_module
          @block = block
        end

        def default_setup(builder)
          @plugin_module.plugin_spec.activate(builder)
        end

        def optional_setup(builder)
          @block && @plugin_module.instance_exec(builder, &@block)
        end

        def version_info
          @plugin_module.plugin_spec.version_info
        end
      end

      class PluginManager
        def initialize(builder)
          @builder = builder
          @plugins = []
        end

        def load_plugin(setup_path_or_name)
          setup_path_or_name = setup_path_or_name.to_s.strip
          setup_path, root_dir =
            if setup_file_directly_given?(setup_path_or_name)
              [setup_path_or_name, extract_root_dir(setup_path_or_name)]
            else
              [get_setup_path(setup_path_or_name), nil]
            end
          read_setup_file(setup_path, setup_path_or_name, root_dir)
        end

        def load_plugins(plugins, no_default_plugins, activation = true)
          RgGen.builder(@builder)
          merge_plugins(plugins, no_default_plugins).each(&method(:load_plugin))
          activation && activate_plugins
        end

        def register_plugin(plugin_module, &block)
          plugin?(plugin_module) ||
            (raise Core::PluginError.new('no plugin spec is given'))
          @plugins << PluginRegistry.new(plugin_module, &block)
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

        def extract_root_dir(setup_path)
          Pathname
            .new(setup_path)
            .ascend.find(&method(:rggen_dir?))
            &.parent
            &.to_s
        end

        def rggen_dir?(path)
          path.each_filename.to_a[-2..-1] == ['lib', 'rggen']
        end

        def get_setup_path(name)
          base, sub_directory = name.split('/', 2)
          base = base.sub(/^rggen[-_]/, '').tr('-', '_')
          File.join(*['rggen', base, sub_directory, 'setup'].compact)
        end

        def read_setup_file(setup_path, setup_path_or_name, root_dir)
          root_dir && $LOAD_PATH.unshift(root_dir)
          require setup_path
        rescue ::LoadError
          message =
            if setup_path_or_name == setup_path
              "cannot load such plugin: #{setup_path_or_name}"
            else
              "cannot load such plugin: #{setup_path_or_name} (#{setup_path})"
            end
          raise Core::PluginError.new(message)
        end

        def merge_plugins(plugins, no_default_plugins)
          [
            *default_plugins(no_default_plugins),
            *plugins_from_env,
            *plugins
          ]
        end

        DEFAULT_PLUGSINS = 'rggen/setup'

        def default_plugins(no_default_plugins)
          load_default_plugins?(no_default_plugins) && DEFAULT_PLUGSINS || nil
        end

        def load_default_plugins?(no_default_plugins)
          return false if no_default_plugins
          return false if ENV.key?('RGGEN_NO_DEFAULT_PLUGINS')
          return false if Gem.find_files(DEFAULT_PLUGSINS).empty?
          true
        end

        def plugins_from_env
          ENV['RGGEN_PLUGINS']
            &.split(':')&.map(&:strip)&.reject(&:empty?)
        end

        def plugin?(plugin_module)
          plugin_module.respond_to?(:plugin_spec) && plugin_module.plugin_spec
        end
      end
    end
  end
end

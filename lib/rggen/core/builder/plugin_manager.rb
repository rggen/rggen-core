# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      DEFAULT_PLUGSINS = 'rggen/default'

      class PluginInfo
        attr_reader :path
        attr_reader :gemname
        attr_reader :version

        def self.parse(path_or_name, version)
          info = new
          info.parse(path_or_name.to_s.strip, version)
          info
        end

        def parse(path_or_name, version)
          @name, @path, @gemname, @version =
            if plugin_path?(path_or_name)
              [nil, path_or_name, *find_gemspec_by_path(path_or_name)]
            else
              [
                path_or_name, get_plugin_path(path_or_name),
                get_gemname(path_or_name), version
              ]
            end
        end

        def to_s
          if @name && @version
            "#{@name} (#{@version})"
          elsif @name
            @name
          else
            @path
          end
        end

        private

        def plugin_path?(path_or_name)
          path_or_name == DEFAULT_PLUGSINS || File.ext(path_or_name) == 'rb'
        end

        def find_gemspec_by_path(path)
          Gem::Specification
            .each.find { |spec| match_gemspec_path?(spec, path) }
            .yield_self { |spec| spec && [spec.name, spec.version] }
        end

        def match_gemspec_path?(gemspec, path)
          gemspec.full_require_paths.any?(&path.method(:start_with?))
        end

        def get_plugin_path(name)
          base_name, sub_name = name.split('/', 2)
          base_name = base_name.sub(/^rggen[-_]/, '').tr('-', '_')
          File.join(*['rggen', base_name, sub_name].compact)
        end

        def get_gemname(name)
          name.split('/', 2).first
        end
      end

      class PluginManager
        def initialize(builder)
          @builder = builder
          @plugins = []
        end

        def load_plugin(path_or_name, version = nil)
          info = PluginInfo.parse(path_or_name, version)
          read_plugin_file(info)
        end

        def load_plugins(plugins, no_default_plugins, activation = true)
          RgGen.builder(@builder)
          merge_plugins(plugins, no_default_plugins)
            .each { |plugin| load_plugin(*plugin) }
          activation && activate_plugins
        end

        def setup_plugin(plugin_name, &block)
          @plugins << PluginSpec.new(plugin_name, &block)
        end

        def activate_plugins
          @plugins.each { |plugin| plugin.activate(@builder) }
        end

        def version_info
          @plugins.map(&:version_info)
        end

        private

        def read_plugin_file(info)
          info.gemname && gem(info.gemname, info.version)
          require info.path
        rescue ::LoadError
          raise Core::PluginError.new("cannot load such plugin: #{info}")
        end

        def merge_plugins(plugins, no_default_plugins)
          [
            *default_plugins(no_default_plugins),
            *plugins_from_env,
            *plugins
          ]
        end

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
            &.split(':')
            &.reject(&:blank?)
            &.map { |entry| entry.split(',', 2) }
        end
      end
    end
  end
end

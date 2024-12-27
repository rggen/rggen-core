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
            if path_or_name == DEFAULT_PLUGSINS || plugin_path?(path_or_name)
              [nil, path_or_name]
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
          File.ext(path_or_name) == 'rb'
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

        def setup_plugin(plugin_name, &)
          @plugins << PluginSpec.new(plugin_name, &)
        end

        def activate_plugins
          do_normal_activation
          do_addtional_activation
        end

        def activate_plugin_by_name(plugin_name)
          @plugins.find { |plugin| plugin.name == plugin_name }
            &.then do |plugin|
              plugin.activate(@builder)
              plugin.activate_additionally(@builder)
            end
        end

        def version_info
          @plugins.map(&:version_info)
        end

        private

        def read_plugin_file(info)
          activate_plugin_gem(info)
          require info.path
        rescue ::LoadError
          raise Core::PluginError.new("cannot load such plugin: #{info}")
        end

        def activate_plugin_gem(info)
          if (gemspec = find_gemspec(info))
            gem gemspec.name, gemspec.version
          elsif info.gemname
            gem info.gemname, info.version
          end
        end

        def find_gemspec(info)
          if info.path == DEFAULT_PLUGSINS
            find_default_plugins_gemspec
          elsif info.gemname
            find_gemspec_by_name(info.gemname, info.version)
          else
            find_gemspec_by_path(info.path)
          end
        end

        def find_default_plugins_gemspec
          find_gemspec_by_name('rggen', "~> #{MAJOR}.#{MINOR}.0")
        end

        def find_gemspec_by_name(name, version)
          Gem::Specification
            .find_all_by_name(name, version)
            .find { |s| !s.has_conflicts? }
        end

        def find_gemspec_by_path(path)
          Gem::Specification
            .each
            .find { |spec| spec.full_require_paths.any?(&path.method(:start_with?)) }
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
          !find_default_plugins_gemspec.nil?
        end

        def plugins_from_env
          ENV['RGGEN_PLUGINS']
            &.split(':')
            &.reject(&:blank?)
            &.map { |entry| entry.split(',', 2) }
        end

        def do_normal_activation
          @plugins.each { |plugin| plugin.activate(@builder) }
        end

        def do_addtional_activation
          @plugins.each { |plugin| plugin.activate_additionally(@builder) }
        end
      end
    end
  end
end

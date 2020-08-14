# frozen_string_literal: true

module RgGen
  module Core
    class HelpPrinter
      def initialize(option_parser)
        @option_parser = option_parser
      end

      def run(_builder, _options)
        puts @option_parser.help
      end
    end

    class VersionPrinter
      def initialize(verbose)
        @verbose = verbose
      end

      def run(builder, options)
        verbose? && load_plugins(builder, options)
        puts version_message(builder)
      end

      private

      def load_plugins(builder, options)
        plugins = options[:plugins]
        no_default_plugins = options[:no_default_plugins]
        builder.load_plugins(plugins, no_default_plugins, false)
      end

      def verbose?
        @verbose
      end

      def version_message(builder)
        [
          simple_version,
          *(verbose? && verbose_version(builder) || nil)
        ].join("\n")
      end

      def simple_version
        "RgGen #{Core::MAJOR}.#{Core::MINOR}"
      end

      def verbose_version(builder)
        [
          "rggen-core #{Core::VERSION}",
          *builder.plugin_manager.version_info
        ].map { |version_info| "  - #{version_info}" }
      end
    end
  end
end

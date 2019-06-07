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
        verbose? && load_setup_file(builder, options[:setup])
        puts help_message(builder)
      end

      private

      def verbose?
        @verbose
      end

      def load_setup_file(builder, file)
        file.nil? || file.empty? || builder.load_setup_file(file)
      end

      def help_message(builder)
        [
          simple_version,
          *(verbose? && verbose_version(builder) || nil)
        ].join("\n")
      end

      def simple_version
        "RgGen #{Core::MAJOR}.#{Core::MINOR}"
      end

      def verbose_version(builder)
        { core: Core::VERSION }
          .merge(builder.library_versions)
          .map { |(lib, version)| "  - rggen-#{lib} #{version}" }
      end
    end
  end
end

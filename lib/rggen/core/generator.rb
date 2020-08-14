# frozen_string_literal: true

module RgGen
  module Core
    class Generator
      def run(builder, options)
        load_plugins(builder, options)
        load_configuration(builder, options[:configuration])
        load_register_map(builder, options.register_map_files)
        write_files(builder, options)
      end

      private

      attr_reader :configuration
      attr_reader :register_map

      def load_plugins(builder, options)
        builder.load_plugins(options[:plugins], options[:no_default_plugins])
      end

      def load_configuration(builder, file)
        @configuration =
          builder
            .build_factory(:input, :configuration)
            .create(Array(file))
      end

      def load_register_map(builder, files)
        files.empty? &&
          (raise Core::LoadError.new('no register map files are given'))
        @register_map =
          builder
            .build_factory(:input, :register_map)
            .create(configuration, files)
      end

      def write_files(builder, options)
        options[:load_only] ||
          file_writers(builder, options[:enable])
            .each { |writer| writer.write_file(options[:output]) }
      end

      def file_writers(builder, targets)
        builder
          .build_factories(:output, targets)
          .map { |factory| factory.create(configuration, register_map) }
      end
    end
  end
end

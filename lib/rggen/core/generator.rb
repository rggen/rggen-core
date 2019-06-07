# frozen_string_literal: true

module RgGen
  module Core
    class Generator
      def run(builder, options)
        load_setup_file(builder, options[:setup])
        load_configuration(builder, options[:configuration])
        load_register_map(builder, options.register_map_files)
        write_files(builder, options)
      end

      private

      attr_reader :configuration
      attr_reader :register_map

      def load_setup_file(builder, file)
        builder.load_setup_file(file)
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
          file_writers(builder, options[:exceptions])
            .each { |writer| writer.write_file(options[:output]) }
      end

      def file_writers(builder, exceptions)
        builder
          .build_factories(:output, exceptions)
          .map { |factory| factory.create(configuration, register_map) }
      end
    end
  end
end

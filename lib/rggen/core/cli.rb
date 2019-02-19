module RgGen
  module Core
    class CLI
      def initialize
        initialize_builder
      end

      def run(args, internal: false)
        error_handler(internal) do
          parse_options(args)
          load_setup
          load_configuration
          load_register_maps
          write_files
        end
      end

      private

      attr_private_reader :builder
      attr_private_reader :options
      attr_private_reader :configuration
      attr_private_reader :register_map

      def initialize_builder
        @builder = Builder::Builder.new
        builder.register_input_components
        ::RgGen.builder(builder)
      end

      def error_handler(internal)
        yield
      rescue OptionParser::ParseError, Core::RuntimeError => e
        internal && raise
        abort "[#{e.class.lastname}] #{e.message}"
      end

      def parse_options(args)
        @options = Options.new
        options.parse(args)
      end

      def load_setup
        file = options[:setup]
        file || (
          raise Core::LoadError.new('no setup file is specified')
        )
        File.readable?(file) || (
          raise Core::LoadError.new('cannot load such file', file)
        )
        load(file)
      end

      def load_configuration
        file = options[:configuration]
        factory = builder.build_input_component_factory(:configuration)
        @configuration = factory.create(Array(file))
      end

      def load_register_maps
        files = options.register_map_files
        files.empty? && (
          raise Core::LoadError.new('no register map files are specified')
        )
        factory = builder.build_input_component_factory(:register_map)
        @register_map = factory.create(configuration, files)
      end

      def write_files
        options[:load_only] && return
        exceptions = options[:exceptions]
        output_directory = Array(options[:output])
        builder.build_output_component_factories(exceptions).each do |factory|
          write_file(factory, output_directory)
        end
      end

      def write_file(factory, output_directory)
        component = factory.create(configuration, register_map)
        component.write_file(output_directory)
      end
    end
  end
end

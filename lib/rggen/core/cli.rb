module RgGen
  module Core
    class CLI
      def initialize
        initialize_builder
      end

      def run(args)
        parse_options(args)
        load_setup
        load_configuration
        load_register_map
        write_files
      end

      private

      attr_private_reader :builder
      attr_private_reader :options
      attr_private_reader :configuration
      attr_private_reader :register_map

      def initialize_builder
        @builder = Builder.create
        RgGen.builder(builder)
      end

      def parse_options(args)
        @options = Options.new
        options.parse(args)
      end

      def load_setup
        options[:setup] || (
          raise Core::LoadError.new('no setup file is given')
        )
        File.readable?(options[:setup]) || (
          raise Core::LoadError.new('cannot load such file', options[:setup])
        )
        load(options[:setup])
      end

      def load_configuration
        @configuration = create_input_component(
          :configuration, Array(options[:configuration])
        )
      end

      def load_register_map
        options.register_map_files.empty? && (
          raise Core::LoadError.new('no register map files are given')
        )
        @register_map = create_input_component(
          :register_map, configuration, options.register_map_files
        )
      end

      def write_files
        options[:load_only] || create_output_components do |component|
          component.write_file(options[:output])
        end
      end

      def create_input_component(component, *args)
        builder
          .build_input_component_factory(component)
          .create(*args)
      end

      def create_output_components
        builder
          .build_output_component_factories(options[:exceptions])
          .each { |f| yield(f.create(configuration, register_map)) }
      end
    end
  end
end

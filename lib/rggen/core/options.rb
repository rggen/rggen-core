module RgGen
  module Core
    class Options
      extend ::Forwardable

      class Option
        def initialize(option_name)
          @option_name = option_name
          block_given? && yield(self)
        end

        def enable(parser, options)
          options[@option_name] ||= default
          parser.on(*args) { |value| handler(value, options, parser) }
        end

        attr_setter :short_option
        attr_setter :long_option
        attr_setter :option_class

        def default(value = nil, &block)
          if block_given?
            @default = block
          elsif !value.nil?
            @default = -> { value }
          elsif @default
            instance_exec(&@default)
          end
        end

        def description(value = nil)
          if value
            @description = value
          else
            @description
          end
        end

        def action(&block)
          if block_given?
            @action = block
          else
            @action || default_action
          end
        end

        private

        def args
          [@short_option, @long_option, @option_class, description].compact
        end

        def default_action
          proc do |value, options, option_name, _parser|
            options[option_name] = value
          end
        end

        def handler(value, options, parser)
          instance_exec(value, options, @option_name, parser, &action)
        end
      end

      def self.options
        @options ||= {}
      end

      def self.add_option(option_name, &body)
        options[option_name] = Option.new(option_name, &body)
      end

      def initialize
        @options = {}
      end

      attr_reader :original_args
      attr_reader :register_map_files

      def_delegator :@options, :[]

      def parse(args)
        @original_arg = args
        @register_map_files = option_parser.parse(args)
      end

      private

      def option_parser
        OptionParser.new do |parser|
          parser.program_name = 'rggen'
          parser.version = RgGen::Core::VERSION
          parser.banner = 'Usage: rggen [options] register_map_files'
          define_options(parser)
        end
      end

      def define_options(parser)
        self.class.options.each_value { |o| o.enable(parser, @options) }
      end
    end

    Options.add_option(:setup) do |option|
      option.long_option '--setup FILE'
      option.default { default_steup_file }
      option.description 'Specify a Ruby file to set up RgGen tool'

      def option.default_steup_file
        if ENV.key?('RGGEN_DEFAULT_SETUP_FILE')
          ENV['RGGEN_DEFAULT_SETUP_FILE']
        else
          require 'lib/rggen/default_setup_file'
          RgGen::DEFAULT_SETUP_FILE
        end
      rescue ::LoadError
        nil
      end
    end

    Options.add_option(:configuration) do |option|
      option.short_option '-c'
      option.long_option '--configuration FILE'
      option.default { default_configuration_file }
      option.description 'Specify a configuration file'

      def option.default_configuration_file
        variable_name = 'RGGEN_DEFAULT_CONFIGURATION_FILE'
        (ENV.key?(variable_name) && ENV[variable_name]) || nil
      end
    end

    Options.add_option(:output) do |option|
      option.short_option '-o'
      option.long_option '--output DIRECTORY'
      option.default { '.' }
      option.description 'Specify the directory where ' \
                         'generated file(s) will be written'
    end

    Options.add_option(:load_only) do |option|
      option.long_option '--load-only'
      option.default false
      option.description 'Load setup, configuration and register map ' \
                         'files only; write no files'
    end

    Options.add_option(:exceptions) do |option|
      option.long_option '--except WRITER1[,WRITER2,...]'
      option.option_class Array
      option.default { [] }
      option.action { |v, o, n| merge_exceptions(v, o, n) }
      option.description 'Disable the given file writer(s)'

      def option.merge_exceptions(value, options, option_name)
        options[option_name].concat(value.map(&:to_sym))
      end
    end

    Options.add_option(:version) do |option|
      option.short_option '-v'
      option.long_option '--version'
      option.action { |*_, parser| display_version(parser) }
      option.description 'Display the version'

      def option.display_version(parser)
        puts parser.ver
        exit
      end
    end

    Options.add_option(:help) do |option|
      option.short_option '-h'
      option.long_option '--help'
      option.action { |*_, parser| display_help(parser) }
      option.description 'Display this message'

      def option.display_help(parser)
        puts parser.help
        exit
      end
    end
  end
end
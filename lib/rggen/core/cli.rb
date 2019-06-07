# frozen_string_literal: true

module RgGen
  module Core
    class CLI
      def initialize
        initialize_builder
      end

      def run(args)
        options = parse_options(args)
        runner(options).run(builder, options)
      end

      private

      attr_reader :builder

      def initialize_builder
        @builder = Builder.create
        RgGen.builder(builder)
      end

      def parse_options(args)
        options = Options.new
        options.parse(args)
        options
      end

      def runner(options)
        options[:runner] || Generator.new
      end
    end
  end
end

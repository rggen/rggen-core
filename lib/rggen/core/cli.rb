# frozen_string_literal: true

module RgGen
  module Core
    class CLI
      def initialize(builder = nil)
        RgGen.builder(builder || Builder.create)
      end

      def run(args)
        options = parse_options(args)
        builder = RgGen.builder
        runner(options).run(builder, options)
      end

      private

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

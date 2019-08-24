# frozen_string_literal: true

module RgGen
  module Core
    class CLI
      def initialize(builder = nil)
        @builder = builder || Builder.create
        @options = Options.new
      end

      attr_reader :builder
      attr_reader :options

      def run(args)
        options.parse(args)
        runner.run(builder, options)
      end

      private

      def runner
        options[:runner] || Generator.new
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    class RgGenError < StandardError
      def initialize(message, additional_info = nil)
        super(message)
        @error_message = message
        @additional_info = additional_info
      end

      attr_reader :error_message
      attr_reader :additional_info

      def to_s
        additional_info ? "#{super} -- #{additional_info}" : super
      end
    end

    class BuilderError < RgGenError
    end

    class PluginError < RgGenError
    end

    class RuntimeError < RgGenError
    end

    class LoadError < Core::RuntimeError
    end

    class GeneratorError < Core::RuntimeError
    end
  end
end

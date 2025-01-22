# frozen_string_literal: true

module RgGen
  module Core
    class RgGenError < StandardError
      def initialize(message, location_info = nil, verbose_info = nil)
        super(message)
        @error_message = message
        @location_info = location_info
        @verbose_info = verbose_info
      end

      attr_reader :error_message
      attr_reader :location_info
      attr_reader :verbose_info

      def to_s
        location_info && "#{super} -- #{location_info}" || super
      end
    end

    class BuilderError < RgGenError
    end

    class PluginError < RgGenError
    end

    class LoadError < RgGenError
    end

    class SourceError < RgGenError
    end

    class GeneratorError < RgGenError
    end
  end
end

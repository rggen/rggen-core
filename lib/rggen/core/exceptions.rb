# frozen_string_literal: true

module RgGen
  module Core
    class RgGenError < StandardError
    end

    class BuilderError < RgGenError
    end

    class RuntimeError < RgGenError
    end

    class LoadError < Core::RuntimeError
      def initialize(message, path = nil)
        super(message)
        @path = path
      end

      def to_s
        @path && (return "#{super} -- #{@path}")
        super
      end
    end
  end
end

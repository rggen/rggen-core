module RgGen
  module Core
    class RgGenError < StandardError
    end

    class RuntimeError < RgGenError
    end

    class LoadError < Core::RuntimeError
      def initialize(message, path)
        super(message)
        @path = path
      end

      def to_s
        "#{super} -- #{@path}"
      end
    end
  end
end

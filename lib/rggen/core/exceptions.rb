module RgGen
  module Core
    class RgGenError < StandardError
    end

    class LoadError < RgGenError
      def initialize(path)
        @path = path
      end

      def to_s
        "cannot load such file -- #{@path}"
      end
    end
  end
end

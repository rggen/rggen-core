module RgGen
  module Core
    class RgGenError < StandardError
    end

    class LoadError < RgGenError
      def initialize(message, path)
        super(message)
        @path = path
      end

      def to_s
        "#{super.to_s} -- #{@path}"
      end
    end
  end
end

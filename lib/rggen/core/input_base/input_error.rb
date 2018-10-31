module RgGen
  module Core
    module InputBase
      class InputError < Core::RuntimeError
        def initialize(message, position = nil)
          super(message)
          @position = position
        end

        def to_s
          return super unless @position
          "#{super} -- #{@position}"
        end
      end
    end
  end
end

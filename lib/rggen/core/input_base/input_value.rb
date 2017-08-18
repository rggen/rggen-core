module RgGen
  module Core
    module InputBase
      class InputValue
        def initialize(value, position)
          @value = value
          @position = position
        end

        attr_reader :value
        attr_reader :position

        def empty_value?
          return true if @value.nil?
          return true if @value.respond_to?(:empty?) && @value.empty?
          false
        end
      end

      NilValue = InputValue.new(nil, nil).freeze
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputValue
        def initialize(value, position)
          @value = (value.is_a?(String) && value.strip) || value
          @position = position
        end

        attr_accessor :value
        attr_reader :position

        def empty_value?
          return true if @value.nil?
          return true if @value.respond_to?(:empty?) && @value.empty?
          false
        end

        def available?
          true
        end
      end

      NAValue = InputValue.new(nil, nil).instance_eval do
        def available?
          false
        end
        freeze
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputValue < ::SimpleDelegator
        NoValue = Object.new

        def initialize(value, options = NoValue, position)
          super((value.is_a?(String) && value.strip) || value)
          @options = options
          @position = position
        end

        alias_method :value, :__getobj__

        attr_reader :position
        attr_reader :options

        def ==(other)
          __getobj__ == other ||
            other.is_a?(InputValue) && __getobj__ == other.__getobj__
        end

        def match_class?(klass)
          __getobj__.is_a?(klass)
        end

        def empty_value?
          return true if value.nil?
          return true if value.respond_to?(:empty?) && value.empty?
          false
        end

        def with_options?
          !@options.equal?(NoValue)
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

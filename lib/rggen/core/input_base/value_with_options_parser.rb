# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class ValueWithOptionsParser < InputValueParser
        def parse(input_value)
          value, options =
            if string?(input_value)
              parse_string_value(input_value)
            else
              Array(input_value).then { |v| [v.first, v[1..]] }
            end
          [value, options || []]
        end

        private

        def parse_string_value(input_value)
          value, option_string = split_string(input_value, ':', 2)
          [value, parse_option_string(option_string)]
        end

        def parse_option_string(option_string)
          split_string(option_string, /[,\n]/, 0)&.map do |option|
            name_value = split_string(option, ':', 2)
            name_value.size == 2 && name_value || name_value.first
          end
        end
      end
    end
  end
end

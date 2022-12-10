# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class HashListParser < InputValueParser
        def parse(input_value)
          list =
            if string?(input_value)
              split_string(input_value, /^\s*$/, 0)
            elsif hash?(input_value) && !input_value.empty?
              [input_value]
            else
              Array(input_value)
            end
          [list.map { |item| parse_hash(item, input_value) }]
        end

        private

        def parse_hash(item, input_value)
          if string?(item)
            parse_string_hash(item)
          else
            Hash(item)
          end
        rescue TypeError, ArgumentError
          error "cannot convert #{item.inspect} into hash", input_value
        end

        def parse_string_hash(item)
          split_string(item, /[,\n]/, 0)
            .map { |element| split_string(element, ':', 2) }
            .to_h
        end
      end
    end
  end
end

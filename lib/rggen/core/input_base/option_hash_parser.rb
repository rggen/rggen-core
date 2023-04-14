# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class OptionHashParser < InputValueParser
        def initialize(exception, allowed_options: nil, multiple_values: false)
          super
          @allowed_options = allowed_options
          @multiple_values = multiple_values
        end

        def parse(input_value)
          values, options = parse_input_value(input_value)
          check_result(values, options, input_value)
          pack_result(values, options)
        end

        private

        def parse_input_value(input_value)
          values, options =
            if string?(input_value)
              parse_string_value(input_value)
            elsif array?(input_value)
              parse_array_value(input_value)
            elsif hash?(input_value)
              [nil, input_value]
            else
              [[input_value.value]]
            end
          [values || [], symbolize_keys(options) || {}]
        end

        def parse_string_value(input_value)
          value_string, option_string = split_string(input_value, ':', 2)
          values = split_string(value_string, /[,\n]/, 0)
          options = parse_option_string(option_string, input_value.position)
          [values, options]
        end

        def parse_option_string(option_string, position)
          do_hash_conversion(option_string, position) do
            split_string(option_string, /[,\n]/, 0)
              &.to_h { |option| split_string(option, ':', 2) }
          end
        end

        def parse_array_value(input_value)
          values, options = split_input_value(input_value)
          [values, parse_option_array(options, input_value.position)]
        end

        def split_input_value(input_value)
          input_value.each_with_object([[], []]) do |item, (values, options)|
            if value_item?(item, values)
              values << item
            else
              options << item
            end
          end
        end

        def value_item?(item, values)
          !hash?(item) && (@multiple_values || values.empty?)
        end

        def parse_option_array(options, position)
          do_hash_conversion(options, position) do
            options.each_with_object({}) do |option, option_hash|
              option_hash.update(option)
            end
          end
        end

        def do_hash_conversion(orinal_value, position)
          yield
        rescue ArgumentError, TypeError
          error "invalid options are given: #{orinal_value.inspect}", position
        end

        def symbolize_keys(options)
          options&.transform_keys { |k| string?(k) && k.to_sym || k }
        end

        def check_result(values, options, input_value)
          no_values?(values, options) &&
            (error "no input values are given: #{input_value.inspect}", input_value)
          illegal_value_size?(values) &&
            (error "multiple input values are given: #{values}", input_value)
          check_option(options, input_value.position)
        end

        def no_values?(values, options)
          values.empty? && !options.empty?
        end

        def illegal_value_size?(values)
          !@multiple_values && values.size > 1
        end

        def check_option(options, position)
          return if @allowed_options.nil? || @allowed_options.empty?
          return if options.nil? || options.empty?

          unknown_options = options.keys - @allowed_options
          unknown_options.empty? ||
            (error "unknown options are given: #{unknown_options}", position)
        end

        def pack_result(values, options)
          [@multiple_values && values || values.first, options]
        end
      end
    end
  end
end

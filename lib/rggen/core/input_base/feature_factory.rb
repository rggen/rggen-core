# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class FeatureFactory < Base::FeatureFactory
        include Utility::TypeChecker

        class << self
          def convert_value(&block)
            @value_converter = block
          end

          attr_reader :value_converter

          def default_value(&block)
            @default_value = block if block_given?
            @default_value
          end

          def allow_options
            @allow_options = true
          end

          def allow_options?
            @allow_options || false
          end
        end

        def create(component, *args)
          input_value = process_input_value(args.last)
          create_feature(component, *args[0..-2], input_value) do |feature|
            build_feature(feature, input_value)
            feature.verify(:feature)
          end
        end

        def active_feature_factory?
          !passive_feature_factory?
        end

        def passive_feature_factory?
          @target_features.nil? && @target_feature.passive_feature?
        end

        private

        def process_input_value(input_value)
          if passive_feature_factory?
            input_value
          elsif self.class.allow_options?
            process_input_value_with_options(input_value)
          else
            process_input_value_without_options(input_value)
          end
        end

        def process_input_value_with_options(input_value)
          value, options =
            if string?(input_value)
              parse_string_value(input_value)
            else
              Array(input_value).then { |values| [values.first, values[1..]] }
            end
          value = convert_value(value, input_value.position) || value
          InputValue.new(value, options || [], input_value.position)
        end

        def parse_string_value(input_value)
          value, options = split_string(input_value, ':', 2)
          [value, parse_option_string(options)]
        end

        def parse_option_string(option_string)
          split_string(option_string, /[,\n]/, 0)&.map do |option|
            name, value = split_string(option, ':', 2)
            value && [name, value] || name
          end
        end

        def split_string(string, separator, limit)
          string&.split(separator, limit)&.map(&:strip)
        end

        def process_input_value_without_options(input_value)
          value = convert_value(input_value.value, input_value.position)
          value && InputValue.new(value, input_value.position) || input_value
        end

        def convert_value(value, position)
          if empty_value?(value)
            evaluate_defalt_value(position)
          else
            convert(value, position)
          end
        end

        def empty_value?(value)
          return true if value.nil?
          return value.empty? if value.respond_to?(:empty?)
          false
        end

        def evaluate_defalt_value(position)
          block = self.class.default_value
          block && instance_exec(position, &block)
        end

        def convert(value, position)
          block = self.class.value_converter
          block && instance_exec(value, position, &block)
        end

        def build_feature(feature, input_value)
          build?(feature, input_value) && feature.build(input_value)
        end

        def build?(feature, input_value)
          active_feature_factory? &&
            input_value.available? &&
            !ignore_empty_value?(feature, input_value)
        end

        def ignore_empty_value?(feature, input_value)
          feature.ignore_empty_value? && input_value.empty_value?
        end
      end
    end
  end
end

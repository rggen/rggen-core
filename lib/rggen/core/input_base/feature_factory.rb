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

          def value_format(format = nil)
            @value_format = format if format
            @value_format
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
          else
            process_active_input_value(input_value)
          end
        end

        def process_active_input_value(input_value)
          parseed_value, options =
            if self.class.value_format
              parse_input_value(input_value, self.class.value_format)
            end
          override_input_value(input_value, parseed_value, options) || input_value
        end

        VALUE_PARSERS = {
          option_array: OptionArrayParser,
          hash_list: HashListParser
        }.freeze

        def parse_input_value(input_value, value_format)
          VALUE_PARSERS[value_format].new(error_exception).parse(input_value)
        end

        def override_input_value(input_value, parseed_value, options)
          (convert_value(input_value, parseed_value) || parseed_value)
            &.then { |v| InputValue.new(v, options, input_value.position) }
        end

        def convert_value(input_value, parseed_value)
          value = parseed_value || input_value.value
          if empty_value?(value)
            evaluate_defalt_value(input_value.position)
          else
            convert(value, input_value.position)
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

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
        end

        def create(component, *args)
          input_value = preprocess(args.last)
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

        def preprocess(input_value)
          converted_value =
            active_feature_factory? && convert_value(input_value)
          converted_value || input_value
        end

        def convert_value(input_value)
          new_value =
            if input_value.empty_value?
              evaluate_defalt_value(input_value.position)
            else
              convert(input_value.value, input_value.position)
            end
          new_value && InputValue.new(new_value, input_value.position)
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

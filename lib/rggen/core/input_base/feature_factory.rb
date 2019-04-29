# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class FeatureFactory < Base::FeatureFactory
        class << self
          def convert_value(&block)
            @value_converter = block
          end

          attr_reader :value_converter
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
          return input_value if passive_feature_factory?
          return input_value if input_value.empty_value?
          return input_value unless value_converter
          InputValue.new(convert(input_value.value), input_value.position)
        end

        def value_converter
          self.class.value_converter
        end

        def convert(value)
          instance_exec(value, &value_converter)
        end

        def build_feature(feature, input_value)
          return if passive_feature_factory?
          return if ignore_empty_value?(feature, input_value)
          feature.build(input_value)
        end

        def ignore_empty_value?(feature, input_value)
          feature.ignore_empty_value? && input_value.empty_value?
        end
      end
    end
  end
end


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
          new_args = [*args.thru(-2), input_value]
          create_feature(component, *new_args) do |feature|
            build_feature(feature, input_value)
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
          passive_feature_factory? && (return input_value)
          input_value.empty_value? && (return input_value)
          value_converter || (return input_value)
          InputValue.new(convert(input_value.value), input_value.position)
        end

        def value_converter
          self.class.value_converter
        end

        def convert(value)
          instance_exec(value, &value_converter)
        end

        def build_feature(feature, input_value)
          passive_feature_factory? && return
          input_value.empty_value? && return
          feature.build(input_value)
        end
      end
    end
  end
end

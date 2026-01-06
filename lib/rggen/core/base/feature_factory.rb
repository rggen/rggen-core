# frozen_string_literal: true

module RgGen
  module Core
    module Base
      class FeatureFactory
        extend SharedContext

        def initialize(feature_name)
          @feature_name = feature_name
          block_given? && yield(self)
        end

        attr_setter :target_feature
        attr_setter :target_features

        def create_feature(component, ...)
          klass, sub_feature_name = select_feature(...)
          klass.new(@feature_name, sub_feature_name, component) do |feature|
            feature.available? || break
            block_given? && yield(feature)
            component.add_feature(feature)
          end
        end

        private

        def select_feature(...)
          key = @target_features && target_feature_key(...)
          feature = (key && @target_features[key]) || @target_feature
          [feature, key]
        end

        def target_feature_key(*args)
        end
      end
    end
  end
end

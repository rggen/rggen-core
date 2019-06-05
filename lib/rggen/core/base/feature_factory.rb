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

        def create_feature(component, *args)
          klass = select_target_feature(*args)
          klass.new(component, @feature_name) do |feature|
            feature.available? || break
            block_given? && yield(feature)
            component.add_feature(feature)
          end
        end

        private

        def select_target_feature(*args)
          (@target_features && select_feature(*args)) || @target_feature
        end

        def select_feature(*args)
        end
      end
    end
  end
end

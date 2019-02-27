# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Component < Base::Component
        def add_feature(feature)
          super
          define_property_methods(feature)
        end

        def properties
          @features.each_value.flat_map(&:properties)
        end

        def validate
          @features.each_value(&:validate)
          @children.each(&:validate)
        end

        private

        def define_property_methods(feature)
          target = "@features[:#{feature.feature_name}]"
          def_delegators(target, *feature.properties)
        end
      end
    end
  end
end

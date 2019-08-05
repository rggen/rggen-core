# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Component < Base::Component
        def add_feature(feature)
          super
          define_proxy_calls(feature, feature.properties)
        end

        def properties
          @features.each_value.flat_map(&:properties)
        end

        def verify(scope)
          @features.each_value { |feature| feature.verify(scope) }
          @children.each { |child| child.verify(scope) } if scope == :all
        end
      end
    end
  end
end

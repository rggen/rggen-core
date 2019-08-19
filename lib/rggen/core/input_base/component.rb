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
          features.flat_map(&:properties)
        end

        def verify(scope)
          features.each { |feature| feature.verify(scope) }
          children.each { |child| child.verify(scope) } if scope == :all
        end

        def printables
          features.select(&:printable?).flat_map(&:printables).to_h
        end
      end
    end
  end
end

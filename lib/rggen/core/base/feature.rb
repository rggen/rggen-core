# frozen_string_literal: true

module RgGen
  module Core
    module Base
      class Feature
        include InternalStruct
        extend SharedContext
        extend Forwardable

        def initialize(component, feature_name)
          @component = component
          @feature_name = feature_name
          post_initialize
          block_given? && yield(self)
        end

        attr_reader :component
        attr_reader :feature_name

        class << self
          private

          def define_helpers(&body)
            singleton_class.class_exec(&body)
          end

          def available?(&body)
            define_method(:available?, &body)
          end

          def printable(&body)
            body && define_method(:printable, &body)
            body && define_method(:printable?) { true }
          end
        end

        available? { true }

        def printable?
          false
        end

        private

        def post_initialize
        end

        def helper
          self.class
        end
      end
    end
  end
end

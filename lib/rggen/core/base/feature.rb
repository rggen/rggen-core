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
          attr_reader :printables

          private

          def define_helpers(&body)
            singleton_class.class_exec(&body)
          end

          def available?(&body)
            define_method(:available?, &body)
          end

          def printable(name, &body)
            @printables ||= {}
            @printables[name] = body
          end

          def inherited(subclass)
            export_instance_variable(:@printables, subclass, &:dup)
          end
        end

        available? { true }

        def printables
          helper
            .printables
            &.map { |name, body| [name, instance_exec(&body)] }
        end

        def printable?
          !helper.printables.nil?
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

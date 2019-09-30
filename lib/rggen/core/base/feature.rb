# frozen_string_literal: true

module RgGen
  module Core
    module Base
      class Feature
        extend InternalStruct
        extend SharedContext
        extend Forwardable

        def initialize(feature_name, sub_feature_name, component)
          @feature_name = feature_name
          @sub_feature_name = sub_feature_name
          @component = component
          post_initialize
          block_given? && yield(self)
        end

        attr_reader :component

        def feature_name(verbose: false)
          if verbose
            [@feature_name, @sub_feature_name]
              .compact.reject(&:empty?).join(':')
          else
            @feature_name
          end
        end

        def inspect
          "#{feature_name(verbose: true)}(#{component})"
        end

        class << self
          attr_reader :printables

          private

          def define_helpers(&body)
            singleton_class.class_exec(&body)
          end

          def available?(&body)
            define_method(:available?, &body)
          end
        end

        available? { true }

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

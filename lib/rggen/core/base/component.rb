# frozen_string_literal: true

module RgGen
  module Core
    module Base
      class Component
        def initialize(base_name, *args)
          @base_name = base_name
          @parent = args.first
          @children = []
          @need_children = true
          @level = (parent && parent.level + 1) || 0
          @features = {}
          post_initialize(*args)
          block_given? && yield(self)
        end

        attr_reader :parent
        attr_reader :children
        attr_reader :level

        def component_name
          [hierarchy, @base_name].compact.join('@')
        end

        def hierarchy
        end

        alias_method :to_s, :component_name

        def need_children?
          @need_children
        end

        def need_no_children
          @need_children = false
        end

        def add_child(child)
          need_children? && (children << child)
        end

        def add_feature(feature)
          @features[feature.feature_name] = feature
        end

        def features
          @features.values
        end

        def feature(key)
          @features[key]
        end

        private

        def post_initialize(*argv)
        end

        def define_proxy_calls(receiver, methods)
          Array(methods)
            .map(&:to_sym)
            .each { |method| define_proxy_call(receiver, method) }
        end

        def define_proxy_call(receiver, method)
          @proxy_calls ||= {}
          @proxy_calls[method] = ProxyCall.new(receiver, method)
          define_singleton_method(method) do |*args, &block|
            @proxy_calls[__method__].call(*args, &block)
          end
        end
      end
    end
  end
end

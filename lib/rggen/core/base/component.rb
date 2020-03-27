# frozen_string_literal: true

module RgGen
  module Core
    module Base
      class Component
        def initialize(parent, base_name, layer, *args)
          @parent = parent
          @base_name = base_name
          @layer = layer
          @children = []
          @need_children = true
          @features = {}
          @component_index = parent&.children&.size || 0
          post_initialize(*args)
          block_given? && yield(self)
        end

        attr_reader :parent
        attr_reader :layer
        attr_reader :children
        attr_reader :component_index

        def component_name
          [@layer, @base_name].compact.join('@')
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

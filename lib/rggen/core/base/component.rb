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
          @depth = (parent&.depth || 0) + 1
          @component_index = parent&.children&.size || 0
          post_initialize(*args)
          block_given? && yield(self)
        end

        attr_reader :parent
        attr_reader :layer
        attr_reader :children
        attr_reader :depth
        attr_reader :component_index

        def ancestors
          [].tap do |components|
            component = self
            while component
              components.unshift(component)
              component = component.parent
            end
          end
        end

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
            .each { |method| define_proxy_call(receiver, method) }
        end

        def define_proxy_call(receiver, method_name)
          (@proxy_receivers ||= {})[method_name.to_sym] = receiver
          define_singleton_method(method_name) do |*args, **keywords, &block|
            name = __method__
            if RUBY_VERSION < '2.7.0' && keywords.empty?
              @proxy_receivers[name].__send__(name, *args, &block)
            else
              @proxy_receivers[name].__send__(name, *args, **keywords, &block)
            end
          end
        end
      end
    end
  end
end

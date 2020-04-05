# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Layer
        class Proxy
          def initialize
            block_given? && yield(self)
          end

          attr_setter :body
          attr_setter :method_name
          attr_setter :list_names
          attr_setter :feature_names

          def shared_context(&body)
            if block_given?
              @shared_context ||= Object.new
              @shared_context.instance_eval(&body)
            end
            @shared_context
          end

          def register_execution(registry, &body)
            @executions ||= []
            @executions << { registry: registry, body: body }
          end

          def execute(layer)
            Docile.dsl_eval(layer, &body)
            @executions&.each(&method(:call_execution))
          end

          private

          def call_execution(execution)
            args = [list_names, feature_names, shared_context].compact
            execution[:registry]
              .__send__(method_name, *args, &execution[:body])
          end
        end

        def initialize(name)
          @name = name
          @feature_registries = {}
        end

        def add_feature_registry(name, registry)
          @feature_registries[name] = registry
          define_proxy_call(name)
        end

        def shared_context(&body)
          block_given? && @proxy&.shared_context(&body)
        end

        def define_simple_feature(feature_names, &body)
          do_proxy_call do |proxy|
            proxy.body(body)
            proxy.method_name(__method__)
            proxy.feature_names(feature_names)
          end
        end

        def define_list_feature(list_names, &body)
          do_proxy_call do |proxy|
            proxy.body(body)
            proxy.method_name(__method__)
            proxy.list_names(list_names)
          end
        end

        def define_list_item_feature(list_name, feature_names, &body)
          do_proxy_call do |proxy|
            proxy.body(body)
            proxy.method_name(__method__)
            proxy.list_names(list_name)
            proxy.feature_names(feature_names)
          end
        end

        def enable(feature_or_list_names, feature_names = nil)
          @feature_registries.each_value do |registry|
            registry.enable(feature_or_list_names, feature_names)
          end
        end

        def disable(feature_or_list_names = nil, feature_names = nil)
          @feature_registries.each_value do |registry|
            registry.disable(*[feature_or_list_names, feature_names].compact)
          end
        end

        def delete(feature_or_list_names = nil, feature_names = nil)
          @feature_registries.each_value do |registry|
            registry.delete(*[feature_or_list_names, feature_names].compact)
          end
        end

        private

        def define_proxy_call(name)
          define_singleton_method(name) do |&body|
            @proxy.register_execution(@feature_registries[__method__], &body)
          end
        end

        def do_proxy_call(&block)
          @proxy = Proxy.new(&block)
          @proxy.execute(self)
          remove_instance_variable(:@proxy)
        end
      end
    end
  end
end

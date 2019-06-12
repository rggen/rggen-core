# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Category
        class Proxy
          def initialize(body)
            body.call(self)
          end

          attr_setter :method
          attr_setter :list_names
          attr_setter :feature_names

          def shared_context(&body)
            if block_given?
              @shared_context ||= Object.new
              @shared_context.instance_eval(&body)
            end
            @shared_context
          end

          def register_execution(registry, args, body)
            @executions ||= []
            @executions << { registry: registry, args: args, body: body }
          end

          def execute(category, body)
            Docile.dsl_eval(category, &body)
            Array(@executions).each { |execution| call_execution(execution) }
          end

          private

          def call_execution(execution)
            send_args = [
              list_names, feature_names, shared_context, *execution[:args]
            ].compact
            execution[:registry].__send__(
              method, *send_args, &execution[:body]
            )
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
          do_proxy_call(body) do |proxy|
            proxy.method(__method__)
            proxy.feature_names(feature_names)
          end
        end

        def define_list_feature(list_names, &body)
          do_proxy_call(body) do |proxy|
            proxy.method(__method__)
            proxy.list_names(list_names)
          end
        end

        def define_list_item_feature(list_name, feature_names, &body)
          do_proxy_call(body) do |proxy|
            proxy.method(__method__)
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
          define_singleton_method(name) do |*args, &body|
            @proxy.register_execution(@feature_registries[name], args, body)
          end
        end

        def do_proxy_call(body, &proxy_block)
          @proxy = Proxy.new(proxy_block)
          @proxy.execute(self, body)
          remove_instance_variable(:@proxy)
        end
      end
    end
  end
end

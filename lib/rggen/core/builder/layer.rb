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
          attr_setter :list_name
          attr_setter :feature_name

          def register_execution(registry, &body)
            @executions ||= []
            @executions << { registry: registry, body: body }
          end

          def execute(layer)
            Docile.dsl_eval(layer, &body)
            @executions&.each { |execution| call_execution(layer, execution) }
          end

          private

          def call_execution(layer, execution)
            args = [list_name, feature_name, layer.shared_context].compact
            execution[:registry].__send__(method_name, *args, &execution[:body])
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
          return unless @proxy

          if block_given?
            context = current_shared_context(true)
            context.singleton_exec(&body)
          end

          current_shared_context(false)
        end

        def define_simple_feature(feature_names, &body)
          Array(feature_names).each do |feature_name|
            do_proxy_call do |proxy|
              proxy.body(body)
              proxy.method_name(__method__)
              proxy.feature_name(feature_name)
            end
          end
        end

        def define_list_feature(list_names, &body)
          Array(list_names).each do |list_name|
            do_proxy_call do |proxy|
              proxy.body(body)
              proxy.method_name(__method__)
              proxy.list_name(list_name)
            end
          end
        end

        def define_list_item_feature(list_name, feature_names, &body)
          Array(feature_names).each do |feature_name|
            do_proxy_call do |proxy|
              proxy.body(body)
              proxy.method_name(__method__)
              proxy.list_name(list_name)
              proxy.feature_name(feature_name)
            end
          end
        end

        def enable(feature_or_list_names, feature_names = nil)
          @feature_registries.each_value do |registry|
            registry.enable(feature_or_list_names, feature_names)
          end
        end

        def enable_all
          @feature_registries.each_value(&:enable_all)
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

        def current_shared_context(allocate)
          list_name = @proxy.list_name || @proxy.feature_name
          feature_name = @proxy.feature_name
          allocate && (shared_contexts[list_name][feature_name] ||= Object.new)
          shared_contexts[list_name][feature_name]
        end

        def shared_contexts
          @shared_contexts ||= Hash.new { |h, k| h[k] = {} }
        end
      end
    end
  end
end

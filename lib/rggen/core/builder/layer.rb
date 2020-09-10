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
          attr_setter :shared_context

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
            args = [list_name, feature_name, shared_context].compact
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
          context = allocate_shared_context
          context.instance_eval(&body) if block_given?
          @proxy.shared_context(context)
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

        def allocate_shared_context
          list_name = @proxy.list_name || @proxy.feature_name
          feature_name = @proxy.feature_name
          shared_contexts[list_name][feature_name]
        end

        def shared_contexts
          @shared_contexts ||= Hash.new do |h0, k0|
            h0[k0] = Hash.new { |h1, k1| h1[k1] = Object.new }
          end
        end
      end
    end
  end
end

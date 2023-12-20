# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Layer
        class Proxy
          def initialize(list_name, feature_name)
            @list_name = list_name
            @feature_name = feature_name
          end

          attr_reader :list_name
          attr_reader :feature_name

          def register_execution(registry, &body)
            @executions ||= []
            @executions << { registry: registry, body: body }
          end

          def execute(layer, method_name, &body)
            Docile.dsl_eval(layer, &body)
            return unless @executions

            args = [list_name, feature_name, layer.shared_context].compact
            @executions.each do |execution|
              execution[:registry].__send__(method_name, *args, &execution[:body])
            end
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

        def component_defined?(component_name)
          @feature_registries.key?(component_name)
        end

        def define_feature(feature_names, &body)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, nil, feature_name, &body)
          end
        end

        def modify_feature(feature_names, &body)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, nil, feature_name, &body)
          end
        end

        def define_simple_feature(feature_names, &body)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, nil, feature_name, &body)
          end
        end

        def modify_simple_feature(feature_names, &body)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, nil, feature_name, &body)
          end
        end

        def define_list_feature(list_names, &body)
          Array(list_names).each do |list_name|
            do_proxy_call(__method__, list_name, nil, &body)
          end
        end

        def modify_list_feature(list_names, &body)
          Array(list_names).each do |list_name|
            do_proxy_call(__method__, list_name, nil, &body)
          end
        end

        def define_list_item_feature(list_name, feature_names, &body)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, list_name, feature_name, &body)
          end
        end

        def modify_list_item_feature(list_name, feature_names, &body)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, list_name, feature_name, &body)
          end
        end

        def enable(...)
          @feature_registries.each_value do |registry|
            registry.enable(...)
          end
        end

        def enable_all
          @feature_registries.each_value(&:enable_all)
        end

        def delete(...)
          @feature_registries.each_value do |registry|
            registry.delete(...)
          end
        end

        def delete_all
          @feature_registries.each_value(&:delete_all)
        end

        private

        def define_proxy_call(name)
          define_singleton_method(name) do |&body|
            @proxy.register_execution(@feature_registries[__method__], &body)
          end
        end

        def do_proxy_call(method_name, list_name, feature_name, &body)
          @proxy = Proxy.new(list_name, feature_name)
          @proxy.execute(self, method_name, &body)
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

# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class Layer
        class Proxy
          def initialize(**proxy_config)
            @proxy_config = proxy_config
          end

          def feature_name
            @proxy_config[:feature_name]
          end

          def list_name
            @proxy_config[:list_name]
          end

          def register_execution(registry, &body)
            @executions ||= Hash.new { |h, k| h[k] = [] }
            @executions[registry] << body
          end

          def execute(layer, method_name, &)
            Docile.dsl_eval(layer, &)
            return unless @executions

            args = execution_args(layer)
            @executions.each do |(registry, bodies)|
              registry.__send__(method_name, *args, bodies)
            end
          end

          private

          def execution_args(layer)
            args = []
            [:list_name, :feature_name, :use_shared_context].each do |key|
              next unless @proxy_config.key?(key)

              args <<
                if key != :use_shared_context
                  @proxy_config[key]
                elsif @proxy_config[key]
                  layer.shared_context
                end
            end

            args
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

        def component(name, &)
          registory =
            @feature_registries
              .fetch(name) { raise BuilderError.new("unknown component: #{name}") }
          block_given? && @proxy.register_execution(registory, &)
        end

        def shared_context(&)
          return unless @proxy

          if block_given?
            context = current_shared_context(true)
            context.singleton_exec(&)
          end

          current_shared_context(false)
        end

        def component_defined?(component_name)
          @feature_registries.key?(component_name)
        end

        def define_feature(feature_names, &)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, feature_name:, use_shared_context: true, &)
          end
        end

        def modify_feature(feature_names, &)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, feature_name:, &)
          end
        end

        def define_simple_feature(feature_names, &)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, feature_name:, use_shared_context: true, &)
          end
        end

        def modify_simple_feature(feature_names, &)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, feature_name:, &)
          end
        end

        def define_list_feature(list_names, &)
          Array(list_names).each do |list_name|
            do_proxy_call(__method__, list_name:, use_shared_context: true, &)
          end
        end

        def modify_list_feature(list_names, &)
          Array(list_names).each do |list_name|
            do_proxy_call(__method__, list_name:, &)
          end
        end

        def define_list_item_feature(list_name, feature_names, &)
          Array(feature_names).each do |feature_name|
            do_proxy_call(
              __method__, list_name:, feature_name:, use_shared_context: true, &
            )
          end
        end

        def modify_list_item_feature(list_name, feature_names, &)
          Array(feature_names).each do |feature_name|
            do_proxy_call(__method__, list_name:, feature_name:, &)
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
            component(__method__, &body)
          end
        end

        def do_proxy_call(method_name, **proxy_config, &)
          @proxy = Proxy.new(**proxy_config)
          @proxy.execute(self, method_name, &)
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

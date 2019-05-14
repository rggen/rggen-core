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
          attr_setter :list_name
          attr_setter :list_names
          attr_setter :feature_names
          attr_setter :shared_context
          attr_setter :block

          def execute(feature_registry, args, body)
            send_args = [
              list_name, list_names, feature_names, shared_context, *args
            ].compact
            feature_registry.__send__(method, *send_args, &body)
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
          return unless block_given?
          return unless @proxy
          @proxy.shared_context&.instance_exec(&body)
        end

        def define_simple_feature(feature_names, **options, &block)
          do_proxy_call do |proxy|
            proxy.method(__method__)
            proxy.feature_names(feature_names)
            proxy.shared_context(create_shared_context(options))
            proxy.block(block)
          end
        end

        def define_list_feature(list_names, **options, &block)
          do_proxy_call do |proxy|
            proxy.method(__method__)
            proxy.list_names(list_names)
            proxy.shared_context(create_shared_context(options))
            proxy.block(block)
          end
        end

        def define_list_item_feature(list_name, feature_names, **options, &block)
          do_proxy_call do |proxy|
            proxy.method(__method__)
            proxy.list_names(list_name)
            proxy.feature_names(feature_names)
            proxy.shared_context(create_shared_context(options))
            proxy.block(block)
          end
        end

        def enable(feature_or_list_names, feature_names = nil)
          @feature_registries.each_value do |registry|
            registry.enable(feature_or_list_names, feature_names)
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
            @proxy.execute(@feature_registries[name], args, body)
          end
        end

        def do_proxy_call(&proxy_block)
          @proxy = Proxy.new(proxy_block)
          Docile.dsl_eval(self, &@proxy.block)
          remove_instance_variable(:@proxy)
        end

        def create_shared_context(options)
          (options[:shared_context] && Object.new) || nil
        end
      end
    end
  end
end

module RgGen
  module Core
    module Builder
      class Category
        Context = Struct.new(
          :method_name, :shared_context, :list_name, :feature_name
        ) do
          def do_definition(featre_registry, body)
            args = []
            args << shared_context
            list_name && (args << list_name)
            feature_name && (args << feature_name)
            featre_registry.__send__(method_name, *args, &body)
          end
        end

        def initialize
          @feature_registries = {}
        end

        def add_feature_registry(name, registry)
          @feature_registries[name] = registry
          define_definition_method(name)
        end

        def shared_context(&body)
          block_given? || return
          @context || return
          @context.shared_context&.instance_exec(&body)
        end

        def define_simple_feature(feature_names, shared_context: false, &body)
          Array(feature_names).each do |feature_name|
            define_feature(
              :define_simple_feature, shared_context, nil, feature_name, body
            )
          end
        end

        def define_list_feature(list_names, feature_nams = nil, shared_context: false, &body)
          if feature_nams
            list_name = list_names
            Array(feature_nams).each do |feature_name|
              define_feature(
                :define_list_feature, shared_context, list_name, feature_name, body
              )
            end
          else
            Array(list_names).each do |list_name|
              define_feature(
                :define_list_feature, shared_context, list_name, nil, body
              )
            end
          end
        end

        def enable(feature_or_list_names, feature_names = nil)
          @feature_registries.each_value do |registry|
            registry.enable(feature_or_list_names, feature_names)
          end
        end

        private

        def define_definition_method(name)
          define_singleton_method(name) do |&body|
            @context.do_definition(@feature_registries[name], body)
          end
        end

        def define_feature(method_name, shared_context, list_name, feature_name, body)
          @context = create_context(
            method_name, shared_context, list_name, feature_name
          )
          Docile.dsl_eval(self, &body)
          remove_instance_variable(:@context)
        end

        def create_context(method_name, shared_context, list_name, feature_name)
          context = Context.new
          context.method_name = method_name
          context.shared_context = Object.new if shared_context
          context.list_name = list_name
          context.feature_name = feature_name
          context
        end
      end
    end
  end
end

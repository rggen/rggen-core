# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class ListFeatureEntry
        def initialize(registry, name)
          @registry = registry
          @name = name
          @features = {}
        end

        attr_reader :registry
        attr_reader :name

        def setup(base_feature, base_factory, context, body)
          @base_feature = Class.new(base_feature)
          @factory = Class.new(base_factory)
          context && apply_shared_context(context)
          body && Docile.dsl_eval(self, &body)
        end

        def match_entry_type?(entry_type)
          entry_type == :list
        end

        def define_factory(&body)
          @factory.class_exec(&body)
        end

        alias_method :factory, :define_factory

        def build_factory(enabled_features)
          @factory.new(@name) do |f|
            f.target_features(target_features(enabled_features))
            f.target_feature(@default_feature)
          end
        end

        def define_base_feature(&body)
          body && @base_feature.class_exec(&body)
        end

        alias_method :base_feature, :define_base_feature

        def define_feature(feature_name, context = nil, &body)
          @features[feature_name] ||= Class.new(@base_feature)
          feature = @features[feature_name]
          if context
            feature.private_method_defined?(:shared_context) && (
              raise BuilderError.new('shared context has already been set')
            )
            feature.shared_context(context)
          end
          body && feature.class_exec(&body)
        end

        alias_method :feature, :define_feature

        def define_default_feature(&body)
          @default_feature ||= Class.new(@base_feature)
          body && @default_feature.class_exec(&body)
        end

        alias_method :default_feature, :define_default_feature

        def defined_feature?(feature)
          @features.key?(feature)
        end

        private

        def apply_shared_context(context)
          @factory.shared_context(context)
          @base_feature.shared_context(context)
          singleton_exec do
            include Base::SharedContext
            shared_context(context)
          end
        end

        def target_features(enabled_features)
          enabled_features
            .select { |n| @features.key?(n) }
            .map { |n| [n, @features[n]] }
            .to_h
        end
      end
    end
  end
end

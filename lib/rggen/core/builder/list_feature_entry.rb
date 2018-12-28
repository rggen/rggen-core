module RgGen
  module Core
    module Builder
      class ListFeatureEntry
        def initialize(name, base_factory, base_feature, context)
          @name = name
          @factory = Class.new(base_factory)
          @base_feature = Class.new(base_feature)
          @features = {}
          @eanbled_features = []
          context && set_shared_context(context)
        end

        def define_factory(&body)
          @factory.class_exec(&body)
        end

        alias_method :factory, :define_factory

        def build_factory
          @factory.new(@name) do |f|
            f.target_features(target_features)
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

        def enable(feature_or_features)
          @eanbled_features.merge!(Array(feature_or_features))
        end

        private

        def set_shared_context(context)
          @factory.shared_context(context)
          @base_feature.shared_context(context)
          singleton_exec do
            include Base::SharedContext
            shared_context(context)
          end
        end

        def target_features
          @eanbled_features.each_with_object({}) do |feature_name, features|
            @features.key?(feature_name) || next
            features[feature_name] = @features[feature_name]
          end
        end
      end
    end
  end
end

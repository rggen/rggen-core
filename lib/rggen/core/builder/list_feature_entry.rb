# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class ListFeatureEntry < FeatureEntryBase
        include Base::SharedContext

        def initialize(registry, name)
          super
          @features = {}
        end

        def setup(base_feature, base_factory, context, &)
          @base_feature = Class.new(base_feature)
          @factory = Class.new(base_factory)
          attach_shared_context(context, @base_feature, @factory, self)
          eval_body(&)
        end

        def define_factory(&)
          @factory.class_exec(&)
        end

        alias_method :factory, :define_factory

        def define_base_feature(&body)
          body && @base_feature.class_exec(&body)
        end

        alias_method :base_feature, :define_base_feature

        def define_feature(feature_name, context = nil, &body)
          feature = @features[feature_name] = Class.new(@base_feature)
          if context
            feature.method_defined?(:shared_context) &&
              (raise BuilderError.new('shared context has already been set'))
            attach_shared_context(context, feature)
          end
          body && feature.class_exec(feature_name, &body)
        end

        alias_method :feature, :define_feature

        def modify_feature(feature_name, &body)
          @features.key?(feature_name) ||
            (raise BuilderError.new("unknown feature: #{feature_name}"))
          body && @features[feature_name].class_exec(feature_name, &body)
        end

        def define_default_feature(&body)
          @default_feature ||= Class.new(@base_feature)
          body && @default_feature.class_exec(&body)
        end

        alias_method :default_feature, :define_default_feature

        def delete(features = nil)
          if features
            Array(features).each { |feature| @features.delete(feature) }
          else
            @features.clear
          end
        end

        def feature?(feature)
          @features.key?(feature)
        end

        def features
          @features.keys
        end

        private

        def entry_type_name
          :list
        end

        def target_features(targets)
          targets && @features.slice(*targets) || @features
        end

        def target_feature
          @default_feature
        end
      end
    end
  end
end

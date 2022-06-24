# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class ListFeatureEntry
        include Base::SharedContext

        def initialize(registry, name)
          @registry = registry
          @name = name
          @features = {}
        end

        attr_reader :registry
        attr_reader :name

        def setup(base_feature, base_factory, context, &body)
          @base_feature = Class.new(base_feature)
          @factory = Class.new(base_factory)
          context && attach_shared_context(context)
          block_given? && Docile.dsl_eval(self, @name, &body)
        end

        def match_entry_type?(entry_type)
          entry_type == :list
        end

        def define_factory(&body)
          @factory.class_exec(&body)
        end

        alias_method :factory, :define_factory

        def build_factory(targets)
          @factory.new(@name) do |f|
            f.target_features(target_features(targets))
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
            feature.method_defined?(:shared_context) &&
              (raise BuilderError.new('shared context has already been set'))
            feature.attach_context(context)
          end
          body && feature.class_exec(feature_name, &body)
        end

        alias_method :feature, :define_feature

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

        private

        def attach_shared_context(context)
          [@factory, @base_feature, self].each do |target|
            target.attach_context(context)
          end
        end

        def target_features(targets)
          targets && @features.slice(*targets) || @features
        end
      end
    end
  end
end

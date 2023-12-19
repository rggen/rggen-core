# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class GeneralFeatureEntry < FeatureEntryBase
        include Base::SharedContext

        def setup(base_feature, base_factory, context, &body)
          @feature = Class.new(base_feature)
          @factory = Class.new(base_factory)
          attach_shared_context(context, @feature, @factory, self)
          eval_body(&body)
        end

        def define_factory(&body)
          @factory.class_exec(&body)
        end

        alias_method :factory, :define_factory

        def define_feature(&body)
          @feature.class_exec(&body)
        end

        alias_method :feature, :define_feature

        private

        def entry_type_name
          :general
        end

        def target_feature
          @feature
        end
      end
    end
  end
end

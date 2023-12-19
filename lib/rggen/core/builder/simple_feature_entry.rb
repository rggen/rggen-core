# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class SimpleFeatureEntry < FeatureEntryBase
        def setup(base_feature, factory, context, &body)
          define_feature(base_feature, context, &body)
          @factory = factory
        end

        private

        def entry_type_name
          :simple
        end

        def define_feature(base, context, &body)
          @feature = Class.new(base)
          attach_shared_context(context, @feature)
          eval_body(&body)
        end

        def target_feature
          @feature
        end

        def eval_body(&body)
          block_given? && @feature.class_exec(@name, &body)
        end
      end
    end
  end
end

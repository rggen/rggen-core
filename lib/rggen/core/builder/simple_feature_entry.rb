# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class SimpleFeatureEntry < FeatureEntryBase
        def setup(base_feature, factory, context)
          define_feature(base_feature, context)
          @factory = factory
        end

        private

        def entry_type_name
          :simple
        end

        def define_feature(base, context)
          @feature = Class.new(base)
          attach_shared_context(context, @feature)
        end

        def target_feature
          @feature
        end

        def eval_body(&)
          block_given? && @feature.class_exec(@name, &)
        end
      end
    end
  end
end

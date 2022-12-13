# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class SimpleFeatureEntry < FeatureEntryBase
        def setup(base_feature, factory, context, &body)
          @feature = define_feature(base_feature, context, &body)
          @factory = factory
        end

        private

        def entry_type_name
          :simple
        end

        def define_feature(base, context, &body)
          feature = Class.new(base)
          attach_shared_context(context, feature)
          block_given? && feature.class_exec(@name, &body)
          feature
        end

        def target_feature
          @feature
        end
      end
    end
  end
end

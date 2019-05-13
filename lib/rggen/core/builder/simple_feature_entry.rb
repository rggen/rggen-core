# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class SimpleFeatureEntry
        def initialize(registry, name)
          @registry = registry
          @name = name
        end

        attr_reader :registry
        attr_reader :name

        def setup(base_feature, factory, context, body)
          @feature = define_feature(base_feature, context, body)
          @factory = factory
        end

        def match_entry_type?(entry_type)
          entry_type == :simple
        end

        def build_factory(_enabled_features)
          @factory.new(@name) { |f| f.target_feature(@feature) }
        end

        private

        def define_feature(base, context, body)
          feature = Class.new(base)
          context && feature.shared_context(context)
          body && feature.class_exec(@name, &body)
          feature
        end
      end
    end
  end
end

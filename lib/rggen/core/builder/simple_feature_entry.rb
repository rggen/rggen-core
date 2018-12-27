module RgGen
  module Core
    module Builder
      class SimpleFeatureEntry
        def initialize(name, factory, base, context, body)
          @name = name
          @factory = factory
          @feature = define_feature(base, context, body)
        end

        def build_factory
          @factory.new(@name) { |f| f.target_feature(@feature) }
        end

        private

        def define_feature(base, context, body)
          feature = Class.new(base)
          context && feature.shared_context(context)
          body && feature.class_exec(&body)
          feature
        end
      end
    end
  end
end

module RgGen
  module Core
    module Builder
      class ComponentEntry
        %i[
          component
          component_factory
          base_feature
          feature_factory
        ].each do |class_name|
          define_method(class_name) do |base, &body|
            klass = (body && Class.new(base, &body)) || base
            instance_variable_set(class_name.variablize, klass)
          end
        end

        def feature_registry
          (@base_feature && @feature_factory) || (return nil)
          @feature_registry ||=
            FeatureRegistry.new(@base_feature, @feature_factory)
        end

        def build_factory
          @component_factory.new do |f|
            f.target_component(@component)
            f.feature_factories(feature_registry&.build_factories)
          end
        end
      end
    end
  end
end

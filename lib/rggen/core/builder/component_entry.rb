# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class ComponentEntry
        Entry = Struct.new(:target, :factory)

        [:component, :feature].each do |entry_name|
          define_method(entry_name) do |target, factory|
            instance_variable_set("@#{__method__}", Entry.new(target, factory))
          end
        end

        def feature_registry
          return unless @feature
          @feature_registry ||= FeatureRegistry.new(*@feature.values)
        end

        def build_factory
          @component.factory.new do |f|
            f.target_component(@component.target)
            f.feature_factories(feature_registry&.build_factories)
          end
        end
      end
    end
  end
end

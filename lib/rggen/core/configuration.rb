# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      def self.setup(builder)
        builder.input_component_registry(:configuration) do
          register_component do
            component Component, ComponentFactory
            feature Feature, FeatureFactory
          end

          base_loader Loader
          register_loaders [RubyLoader, JSONLoader, YAMLLoader]
        end
      end
    end
  end
end

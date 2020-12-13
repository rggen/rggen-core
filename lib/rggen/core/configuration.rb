# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      def self.setup(builder)
        builder.input_component_registry(:configuration) do
          register_component(global: true) do
            component Component, ComponentFactory
            feature Feature, FeatureFactory
          end

          register_loader :ruby, RubyLoader
          register_loader :yaml, YAMLLoader
          register_loader :json, JSONLoader
        end
      end
    end
  end
end

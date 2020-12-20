# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      def self.setup(builder)
        builder.input_component_registry(:configuration) do
          register_global_component do
            component Component, ComponentFactory
            feature Feature, FeatureFactory
          end

          register_loader :ruby, RubyLoader
          register_loader :json, JSONLoader
          register_loader :toml, TOMLLoader
          register_loader :yaml, YAMLLoader
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      def self.setup(builder)
        builder.input_component_registry(:register_map) do
          register_component :register_map do
            component Component, ComponentFactory
          end

          register_component [:register_block, :register, :bit_field] do
            component Component, ComponentFactory
            feature Feature, FeatureFactory
          end

          base_loader Loader
          register_loader RubyLoader
          register_loader JSONLoader
          register_loader YAMLLoader
        end
      end
    end
  end
end

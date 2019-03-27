# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      def self.setup(builder)
        builder.input_component_registry(:register_map) do
          register_component [
            :register_map, :register_block, :register, :bit_field
          ] do |category|
            component Component, ComponentFactory
            feature Feature, FeatureFactory if category != :register_map
          end

          base_loader Loader
          register_loaders [RubyLoader, JSONLoader, YAMLLoader]
        end
      end
    end
  end
end

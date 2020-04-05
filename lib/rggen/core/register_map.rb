# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      def self.setup(builder)
        builder.input_component_registry(:register_map) do
          register_component [
            :root, :register_block, :register_file, :register, :bit_field
          ] do |layer|
            component Component, ComponentFactory
            feature Feature, FeatureFactory if layer != :root
          end

          base_loader Loader
          register_loaders [RubyLoader, JSONLoader, YAMLLoader]
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module Plugin
      attr_reader :plugin_spec

      private

      def setup_plugin(name)
        @plugin_spec = Builder::PluginSpec.new(name, self)
        block_given? && yield(@plugin_spec)
      end
    end
  end
end

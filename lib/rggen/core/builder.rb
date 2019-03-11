# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      def self.create
        builder = Builder.new
        builder.register_input_components
        builder
      end
    end
  end
end

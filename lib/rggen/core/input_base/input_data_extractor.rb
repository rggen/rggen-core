# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputDataExtractor
        def initialize(target_layers)
          @target_layers = Array(target_layers)
        end

        class << self
          attr_reader :extractor

          private

          def extract(&body)
            @extractor = body
          end
        end

        def target_layer?(layer)
          @target_layers.empty? || @target_layers.include?(layer)
        end

        def extract(input_data)
          body = self.class.extractor
          instance_exec(input_data, &body)
        end
      end
    end
  end
end


# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputValueExtractor
        def initialize(target_layers, target_value)
          @target_layers = Array(target_layers)
          @target_value = target_value
        end

        class << self
          attr_reader :extractor

          private

          def extract(&body)
            @extractor = body
          end
        end

        def target_value?(layer, value)
          value == @target_value &&
            (@target_layers.empty? || @target_layers.include?(layer))
        end

        def extract(input_data)
          body = self.class.extractor
          instance_exec(input_data, &body)
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Verifier
        def initialize(block)
          instance_eval(&block)
        end

        def error_condition(&block)
          @error_condition = block
        end

        def message(&block)
          @message = block
        end

        def verify(feature)
          error?(feature) && raise_error(feature)
        end

        private

        def error?(feature)
          feature.instance_eval(&@error_condition)
        end

        def raise_error(feature)
          feature.instance_exec(@message) do |message|
            error(instance_eval(&message))
          end
        end
      end
    end
  end
end

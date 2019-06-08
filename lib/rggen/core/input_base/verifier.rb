# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Verifier
        def initialize(&block)
          instance_eval(&block)
        end

        def check_error(&block)
          @error_checker = block
        end

        def error_condition(&block)
          @condition = block
        end

        def message(&block)
          @message = block
        end

        def verify(feature)
          if @error_checker
            feature.instance_eval(&@error_checker)
          else
            default_error_check(feature)
          end
        end

        private

        def default_error_check(feature)
          feature.instance_exec(@condition, @message) do |condition, message|
            instance_eval(&condition) && error(instance_eval(&message))
          end
        end
      end
    end
  end
end

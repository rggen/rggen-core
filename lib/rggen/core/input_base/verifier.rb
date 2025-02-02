# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Verifier
        def initialize(&)
          instance_eval(&)
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

        def position(&block)
          @position = block
        end

        def verify(feature, *values)
          if @error_checker
            feature.instance_exec(*values, &@error_checker)
          else
            default_error_check(feature, values)
          end
        end

        private

        def default_error_check(feature, values)
          return unless feature.instance_exec(*values, &@condition)

          message = feature.instance_exec(*values, &@message)
          position = @position && feature.instance_exec(*values, &@position)
          feature.__send__(:error, message, position)
        end
      end
    end
  end
end

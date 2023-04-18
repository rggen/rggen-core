# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module Error
        private

        ApproximatelyErrorPosition = Struct.new(:position) do
          def self.create(position)
            position && new(position)
          end

          def to_s
            "#{position} (approximately)"
          end
        end

        def error(message, input_value_or_position = nil)
          position =
            if with_position?(input_value_or_position)
              input_value_or_position.position
            elsif respond_to?(:error_position)
              error_position
            else
              @position || input_value_or_position
            end
          raise error_exception.new(message, position)
        end

        def with_position?(input_value)
          input_value.respond_to?(:position) && input_value.position
        end
      end
    end
  end
end

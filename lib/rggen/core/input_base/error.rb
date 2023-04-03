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

        def error(message, input_value = nil)
          position =
            if input_value.respond_to?(:position) && input_value.position
              input_value.position
            elsif respond_to?(:error_position)
              error_position
            else
              @position
            end
          raise error_exception.new(message, position)
        end
      end
    end
  end
end

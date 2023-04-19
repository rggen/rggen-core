# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      ApproximatelyErrorPosition = Struct.new(:position) do
        def self.create(position)
          position && new(position)
        end

        def to_s
          "#{position} (approximately)"
        end
      end

      module RaiseError
        private

        def error(message, position = nil)
          pos = extract_error_position(position)
          raise error_exception.new(message, pos)
        end

        def extract_error_position(position)
          pos =
            if position.respond_to?(:position)
              position.position
            else
              position
            end
          pos ||
            if respond_to?(:error_position)
              error_position
            else
              @position
            end
        end
      end
    end
  end
end

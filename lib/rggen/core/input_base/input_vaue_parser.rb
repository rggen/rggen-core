# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputValueParser
        include Utility::TypeChecker
        include RaiseError

        def initialize(**_options)
        end

        private

        def split_string(string, separator, limit)
          string&.split(separator, limit)&.map(&:strip)
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module InputValueParser
        private

        include Utility::TypeChecker

        def split_string(string, separator, limit)
          string&.split(separator, limit)&.map(&:strip)
        end
      end
    end
  end
end

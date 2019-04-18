# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module RegexpPatterns
        class << self
          def included(klass)
            klass.extend(self)
          end
        end

        private

        VARIABLE_NAME_PATTERN = /[a-z_]\w*/i.freeze

        def variable_name
          VARIABLE_NAME_PATTERN
        end

        BINARY_PATTERN = /[+-]?0b[01](?:_?[01])*/i.freeze

        DECIMAL_PATTERN = /[+-]?(?:[1-9]_?(?:\d_?)*)?\d/.freeze

        HEXADECIMAL_PATTERN = /[+-]?0x\h(?:_?\h)*/i.freeze

        INTEGER_PATTERN =
          Regexp.union(
            BINARY_PATTERN, DECIMAL_PATTERN, HEXADECIMAL_PATTERN
          ).freeze

        def integer
          INTEGER_PATTERN
        end
      end
    end
  end
end

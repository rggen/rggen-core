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

        VARIABLE_NAME_PATTERN = /[a-z]\w+/i

        def variable_name
          VARIABLE_NAME_PATTERN
        end

        BINARY_PATTERN = /[+-]?0b[01](?:_?[01])*/i

        DECIMAL_PATTERN = /[+-]?(?:[1-9]_?(?:\d_?)*)?\d/

        HEXADECIMAL_PATTERN = /[+-]?0x\h(?:_?\h)*/i

        INTEGER_PATTERN =
          Regexp.union(
            BINARY_PATTERN, DECIMAL_PATTERN, HEXADECIMAL_PATTERN
          ).freeze

        def integer
          INTEGER_PATTERN
        end

        TRUTHY_PATTERN = /true|on|yes/i

        def truthy_pattern
          TRUTHY_PATTERN
        end

        FALSEY_PATTERN = /false|off|no/i

        def falsey_pattern
          FALSEY_PATTERN
        end
      end
    end
  end
end

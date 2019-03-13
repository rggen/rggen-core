module RgGen
  module Core
    module Utility
      module RegexpPatterns
        class << self
          def included(klass)
            klass.extend(self)
          end

          private

          def match_word_pattern(pattern)
            /(?<=(?:\A|\s))#{pattern}(?=(?:\z|\s))/
          end
        end

        private

        VARIABLE_NAME_PATTERN =
          match_word_pattern(/[a-z_][a-z0-9_]*/i).freeze

        def variable_name
          VARIABLE_NAME_PATTERN
        end

        BINARY_PATTERN =
          match_word_pattern(/[+-]?0b[01](?:_?[01])*/i).freeze

        DECIMAL_PATTERN =
          match_word_pattern(/[+-]?(?:[1-9]_?(?:[0-9]_?)*)?[0-9]/).freeze

        HEXADECIMAL_PATTERN =
          match_word_pattern(/[+-]?0x[0-9a-f](?:_?[0-9a-f])*/i).freeze

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

# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputMatcher
        def initialize(pattern_or_patterns, options, &converter)
          @options = options
          @converter = converter
          @pattern = unite_patterns(Array(pattern_or_patterns))
        end

        def match(rhs)
          rhs = rhs.to_s
          rhs = delete_blanks(rhs) if ignore_blanks?
          @pattern.match(rhs, &@converter)
        end

        def match_automatically?
          @options.fetch(:match_automatically, true)
        end

        private

        def unite_patterns(patterns)
          united_pattern = Regexp.union(*patterns)
          if @options.fetch(:match_wholly, true)
            /\A#{united_pattern}\z/
          else
            united_pattern
          end
        end

        def ignore_blanks?
          @options.fetch(:ignore_blanks, true)
        end

        DELETE_BLANK_PATTERN =
          Regexp.union(
            /(?<=\w)[[:blank:]]+(?=[[:punct:]])/,
            /(?<=[[:punct:]])[[:blank:]]+(?=\w)/
          ).freeze

        COMPRESS_BLANK_PATTERN = /([[:blank:]])[[:blank:]]*/.freeze

        def delete_blanks(rhs)
          rhs
            .strip
            .gsub(DELETE_BLANK_PATTERN, '')
            .gsub(COMPRESS_BLANK_PATTERN) { Regexp.last_match[1] }
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputMatcher
        def initialize(pattern, options, &converter)
          @options = options
          @converter = converter
          @pattern =
            if @options.fetch(:match_wholly, true)
              /\A#{pattern}\z/
            else
              pattern
            end
        end

        attr_reader :options

        def match(rhs)
          rhs = rhs.to_s
          rhs = delete_blanks(rhs) if ignore_blanks?
          @pattern.match(rhs, &@converter)
        end

        private

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

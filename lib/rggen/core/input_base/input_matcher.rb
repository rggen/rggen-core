# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputMatcher
        def initialize(pattern_or_patterns, **options, &converter)
          @options = options
          @converter = converter
          @patterns = format_patterns(pattern_or_patterns)
        end

        def match(rhs)
          rhs = rhs.to_s
          rhs = delete_blanks(rhs) if ignore_blanks?
          match_patterns(rhs)
        end

        def match_automatically?
          @options.fetch(:match_automatically, true)
        end

        private

        def format_patterns(pattern_or_patterns)
          if @options.fetch(:match_wholly, true)
            expand_patterns(pattern_or_patterns)
              .transform_values { |pattern| /\A#{pattern}\z/ }
          else
            expand_patterns(pattern_or_patterns)
          end
        end

        def expand_patterns(pattern_or_patterns)
          Array(pattern_or_patterns).each_with_object({}) do |pattern, patterns|
            if pattern.is_a? Hash
              patterns.update(pattern)
            else
              patterns[patterns.size] = pattern
            end
          end
        end

        def ignore_blanks?
          @options.fetch(:ignore_blanks, true)
        end

        DELETE_BLANK_PATTERN =
          Regexp.union(
            /(?<=\w)[[:blank:]]+(?=[[:punct:]&&[^_]])/,
            /(?<=[[:punct:]&&[^_]])[[:blank:]]+(?=\w)/
          ).freeze

        COMPRESS_BLANK_PATTERN = /[[:blank:]]+/.freeze

        def delete_blanks(rhs)
          rhs
            .strip
            .gsub(DELETE_BLANK_PATTERN, '')
            .gsub(COMPRESS_BLANK_PATTERN, ' ')
        end

        def match_patterns(rhs)
          index, match_data =
            @patterns
              .transform_values { |pattern| pattern.match(rhs) }
              .compact
              .max_by { |_, m| m[0].length }
          match_data && [convert_match_data(match_data), index]
        end

        def convert_match_data(match_data)
          @converter&.call(match_data) || match_data
        end
      end
    end
  end
end

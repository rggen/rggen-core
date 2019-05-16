# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputMatcher
        def initialize(pattern_or_patterns, options, &converter)
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

        def format_patterns(patterns)
          if @options.fetch(:match_wholly, true)
            patterns_hash(patterns)
              .map { |i, pattern| [i, /\A#{pattern}\z/] }
              .to_h
          else
            patterns_hash(patterns)
          end
        end

        def patterns_hash(patterns)
          if patterns.is_a?(Hash)
            patterns
          else
            Array(patterns)
              .map.with_index { |pattern, i| [i, pattern] }
              .to_h
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
          match_data, index =
            @patterns
              .map { |i, pattern| pattern.match(rhs) { |m| [m, i] } }
              .compact
              .max { |m| m[0].length }
          match_data && [convert_match_data(match_data), index]
        end

        def convert_match_data(match_data)
          @converter&.call(match_data) || match_data
        end
      end
    end
  end
end

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

        def match(rhs)
          match_data = do_match(rhs)
          return unless match_data
          return match_data unless @converter
          @converter.call(match_data)
        end

        private

        def do_match(rhs)
          rhs = rhs.to_s if @options[:convert_to_string]
          rhs = delete_blanks(rhs)
          case rhs
          when @pattern
            Regexp.last_match
          end
        end

        def delete_blanks(rhs)
          return rhs unless @options.fetch(:ignore_blanks, true)
          return rhs unless rhs.respond_to?(:gsub)
          rhs.gsub(/[[:blank:]]+/, '')
        end
      end
    end
  end
end

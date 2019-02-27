# frozen_string_literal: true

module RgGen
  module Core
    module SpecHelpers
      module MatchValueMatcher
        extend RSpec::Matchers::DSL

        matcher :match_value do |value, position = nil|
          match do |actual|
            return false unless actual.value == value
            return false if position && (actual.position != position)
            true
          end

          failure_message do
            if position
              "expected: #{value.inspect} [#{position}]\n"  \
              "     got: #{actual.value.inspect} [#{actual.position}]\n\n"
            else
              "expected: #{value.inspect}\n"  \
              "     got: #{actual.value.inspect}\n\n"
            end
          end
        end
      end
    end
  end
end

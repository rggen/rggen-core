# frozen_string_literal: true

module RgGen
  module Core
    module SpecHelpers
      module MatchStringMatcher
        extend RSpec::Matchers::DSL

        matcher :match_string do |expected|
          diffable

          @actual = nil

          match do |actual|
            @actual = actual.to_s
            values_match?(expected, @actual)
          end
        end
      end
    end
  end
end

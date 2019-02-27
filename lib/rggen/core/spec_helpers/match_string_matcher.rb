# frozen_string_literal: true

module RgGen
  module Core
    module SpecHelpers
      module MatchStringMatcher
        extend RSpec::Matchers::DSL

        matcher :match_string do |expected|
          match do |actual|
            return true if values_match?(expected, actual)
            return true if values_match?(expected, actual.to_s)
            false
          end
        end
      end
    end
  end
end

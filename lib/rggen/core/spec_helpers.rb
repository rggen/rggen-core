require_relative 'spec_helpers/have_value_matcher.rb'
require_relative 'spec_helpers/have_property_matcher.rb'
require_relative 'spec_helpers/match_string_matcher.rb'

RSpec.configure do |config|
  config.include RgGen::Core::SpecHelpers::HaveValueMatcher
  config.include RgGen::Core::SpecHelpers::HavePropertyMatcher
  config.include RgGen::Core::SpecHelpers::MatchStringMatcher
end

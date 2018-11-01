require_relative 'spec_helpers/have_value_matcher.rb'
require_relative 'spec_helpers/have_field_matcher.rb'
require_relative 'spec_helpers/match_string_matcher.rb'

RSpec.configure do |config|
  config.include RgGen::Core::SpecHelpers::HaveValueMatcher
  config.include RgGen::Core::SpecHelpers::HaveFieldMatcher
  config.include RgGen::Core::SpecHelpers::MatchStringMatcher
end

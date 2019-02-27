# frozen_string_literal: true

require_relative 'spec_helpers/helper_methods'
require_relative 'spec_helpers/have_value_matcher'
require_relative 'spec_helpers/have_property_matcher'
require_relative 'spec_helpers/match_string_matcher'
require_relative 'spec_helpers/match_value_matcher'

RSpec.configure do |config|
  config.include RgGen::Core::SpecHelpers::HelperMethods
  config.include RgGen::Core::SpecHelpers::HaveValueMatcher
  config.include RgGen::Core::SpecHelpers::HavePropertyMatcher
  config.include RgGen::Core::SpecHelpers::MatchStringMatcher
  config.include RgGen::Core::SpecHelpers::MatchValueMatcher
end

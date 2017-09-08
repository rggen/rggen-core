require_relative 'spec_helpers/have_value_matcher.rb'

RSpec.configure do |config|
  config.include RgGen::Core::SpecHelpers::HaveValueMatcher
end

# frozen_string_literal: true

module RgGen
  module Core
    module SpecHelpers
      module HavePropertyMatcher
        extend RSpec::Matchers::DSL

        matcher :have_property do |property, value|
          match do |component|
            @no_property = !component.respond_to?(property)
            @no_property && (return flase)
            @actual = component.public_send(property)
            @actual == value
          end

          failure_message do
            if @no_property
              "no such property: #{property}"
            else
              "expected #{property} to be #{value.inspect} " \
              "but got #{@actual.inspect}"
            end
          end
        end

        def have_properties(properties)
          properties.inject(nil) do |matcher, (property, value)|
            new_matcher = have_property(property, value)
            matcher&.and(new_matcher) || new_matcher
          end
        end
      end
    end
  end
end

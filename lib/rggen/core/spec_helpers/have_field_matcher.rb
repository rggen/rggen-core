module RgGen
  module Core
    module SpecHelpers
      module HaveFieldMatcher
        extend RSpec::Matchers::DSL

        matcher :have_field do |field, value|
          match do |component|
            @no_field = !component.respond_to?(field)
            return false if @no_field
            @actual = component.public_send(field)
            @actual == value
          end

          failure_message do
            if @no_field
              "no such field: #{field}"
            else
              "expected #{field} to be #{value.inspect} " \
              "but got #{@actual.inspect}"
            end
          end
        end

        def have_fields(fields)
          fields.inject(nil) do |matcher, (field, value)|
            next have_field(field, value) unless matcher
            matcher.and have_field(field, value)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module SpecHelpers
      module HaveValueMatcher
        extend RSpec::Matchers::DSL

        matcher :have_value do |name, value = nil, position = nil|
          match do |data|
            @actual = data[name]
            return false if @actual.equal?(InputBase::NilValue)
            return false unless InputBase::InputValue === @actual
            return false if value && @actual.value != value
            return false if position && !match_position?(@actual.position, position)
            true
          end

          failure_message do
            if !@actual
              "no such value included: #{name}"
            elsif position
              "expected to have value[#{name}]: #{value.inspect} (position: #{position}) " \
              "but got #{@actual.value.inspect} (position: #{@actual.position})"
            elsif value
              "expected to have value[#{name}]: #{value.inspect} but got #{@actual.value.inspect}"
            end
          end

          failure_message_when_negated do
            "expect not to have value[#{name}]"
          end

          def match_position?(actual_position, expected_position)
            if [actual_position, expected_position].all? { |position|
              position.kind_of?(Thread::Backtrace::Location)
            }
              actual_position.to_s == expected_position.to_s
            else
              actual_position == expected_position
            end
          end
        end

        def have_values(*expected_values)
          expected_values.inject(nil) do |matcher, expected_value|
            next have_value(*expected_value) unless matcher
            matcher.and have_value(*expected_value)
          end
        end
      end
    end
  end
end

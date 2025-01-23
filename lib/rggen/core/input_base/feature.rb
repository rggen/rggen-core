# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Feature < Base::Feature
        include Utility::RegexpPatterns
        include Utility::TypeChecker
        include RaiseError
        include ConversionUtility

        class << self
          def properties
            feature_array_variable_get(:@properties)
          end

          def active_feature?
            !passive_feature?
          end

          def passive_feature?
            feature_array_variable_get(:@builders).nil?
          end

          private

          def property(name, ...)
            Property.define(self, name, ...)
            properties&.include?(name) ||
              feature_array_variable_push(:@properties, name)
          end

          alias_method :field, :property

          def ignore_empty_value(value)
            @ignore_empty_value = value
          end

          def build(&block)
            feature_array_variable_push(:@builders, block)
          end

          def post_build(&block)
            feature_array_variable_push(:@post_builders, block)
          end

          def input_pattern(pattern_or_patterns, ...)
            @input_matcher = InputMatcher.new(pattern_or_patterns, ...)
          end

          def verify(scope, prepend: false, &)
            verifyier = create_verifier(&)
            if prepend
              feature_hash_array_variable_prepend(:@verifiers, scope, verifyier)
            else
              feature_hash_array_variable_push(:@verifiers, scope, verifyier)
            end
          end

          def create_verifier(&)
            Verifier.new(&)
          end

          def printable(name, &body)
            feature_hash_variable_store(:@printables, name, body)
          end
        end

        def properties
          feature_array_variable_get(:@properties)
        end

        def build(*args)
          builders = feature_array_variable_get(:@builders)
          return unless builders

          do_build(builders, args)
        end

        def post_build
          feature_array_variable_get(:@post_builders)
            &.each { |block| instance_exec(&block) }
        end

        def ignore_empty_value?
          feaure_scala_variable_get(:@ignore_empty_value)
            .then { _1.nil? || _1 }
        end

        def verify(scope)
          verified?(scope) || do_verify(scope)
        end

        def printables
          feature_hash_variable_get(:@printables)
            &.map { |name, body| [name, printable(name, &body)] }
        end

        def printable?
          !feature_hash_variable_get(:@printables).nil?
        end

        def inspect
          printable_values = printables&.map { |name, value| "#{name}: #{value.inspect}" }
          (printable_values && "#{super}[#{printable_values.join(', ')}]") || super
        end

        attr_reader :position

        def error_position
          if position
            position
          else
            approximate_position =
              component.features.map(&:position).find(&:itself)
            ApproximatelyErrorPosition.create(approximate_position)
          end
        end

        private

        def do_build(builders, args)
          @position = args.last.position
          match_automatically? && match_pattern(args.last)
          execute_build_blocks(builders, args)
        end

        def execute_build_blocks(builders, args)
          args = [*args, args.last.options] if args.last.with_options?
          builders.each { |builder| instance_exec(*args, &builder) }
        end

        def input_matcher
          feaure_scala_variable_get(:@input_matcher)
        end

        def match_automatically?
          input_matcher&.match_automatically?
        end

        def match_pattern(rhs)
          @match_data, @match_index = input_matcher&.match(rhs)
        end

        attr_reader :match_data
        attr_reader :match_index

        def pattern_matched?
          !match_data.nil?
        end

        def verified?(scope)
          @verified && @verified[scope]
        end

        def do_verify(scope)
          verifiers = feature_hash_array_variable_get(:@verifiers)
          return unless verifiers

          verifiers[scope]&.each { |verifier| verifier.verify(self) }
          (@verified ||= {})[scope] = true
        end

        def printable(name, &)
          block_given? ? instance_exec(&) : __send__(name)
        end
      end
    end
  end
end

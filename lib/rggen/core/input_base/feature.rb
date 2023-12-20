# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Feature < Base::Feature
        include Utility::RegexpPatterns
        include Utility::TypeChecker
        include ConversionUtility

        class << self
          def property(name, ...)
            Property.define(self, name, ...)
            properties.include?(name) || properties << name
          end

          alias_method :field, :property

          def properties
            @properties ||= []
          end

          def ignore_empty_value(value = nil)
            @ignore_empty_value = value unless value.nil?
            @ignore_empty_value
          end

          def ignore_empty_value?
            @ignore_empty_value.nil? || @ignore_empty_value
          end

          def build(&block)
            (@builders ||= []) << block
          end

          attr_reader :builders

          def post_build(&block)
            (@post_builders ||= []) << block
          end

          attr_reader :post_builders

          def active_feature?
            !passive_feature?
          end

          def passive_feature?
            builders.nil?
          end

          def input_pattern(pattern_or_patterns, ...)
            @input_matcher = InputMatcher.new(pattern_or_patterns, ...)
          end

          attr_reader :input_matcher

          def verify(scope, &block)
            @verifiers ||= {}
            (@verifiers[scope] ||= []) << create_verifier(&block)
          end

          attr_reader :verifiers

          def printable(name, &body)
            (@printables ||= {})[name] = body
          end

          attr_reader :printables

          def inherited(subclass)
            super
            export_instance_variable(:@properties, subclass, &:dup)
            export_instance_variable(:@ignore_empty_value, subclass)
            export_instance_variable(:@builders, subclass, &:dup)
            export_instance_variable(:@post_builders, subclass, &:dup)
            export_instance_variable(:@input_matcher, subclass)
            export_instance_variable(:@printables, subclass, &:dup)
            export_verifiers(subclass) if @verifiers
          end

          private

          def create_verifier(&body)
            Verifier.new(&body)
          end

          def export_verifiers(subclass)
            subclass
              .instance_variable_set(:@verifiers, @verifiers.transform_values(&:dup))
          end
        end

        def_delegator :'self.class', :properties
        def_delegator :'self.class', :active_feature?
        def_delegator :'self.class', :passive_feature?
        def_delegator :'self.class', :ignore_empty_value?

        def build(*args)
          self.class.builders && do_build(args)
        end

        def post_build
          self.class.post_builders&.each { |block| instance_exec(&block) }
        end

        def verify(scope)
          verified?(scope) || do_verify(scope)
        end

        def printables
          helper.printables&.map { |name, body| [name, printable(name, &body)] }
        end

        def printable?
          !helper.printables.nil?
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

        def do_build(args)
          @position = args.last.position
          match_automatically? && match_pattern(args.last)
          execute_build_blocks(args)
        end

        def execute_build_blocks(args)
          args = [*args, args.last.options] if args.last.with_options?
          self.class.builders.each { |builder| instance_exec(*args, &builder) }
        end

        def match_automatically?
          self.class.input_matcher&.match_automatically?
        end

        def match_pattern(rhs)
          @match_data, @match_index = self.class.input_matcher&.match(rhs)
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
          self.class.verifiers&.[](scope)&.each { |verifier| verifier.verify(self) }
          (@verified ||= {})[scope] = true
        end

        def printable(name, &body)
          block_given? ? instance_exec(&body) : __send__(name)
        end
      end
    end
  end
end

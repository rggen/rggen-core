# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Feature < Base::Feature
        include Utility::RegexpPatterns

        class << self
          def property(name, **options, &body)
            Property.define(self, name, **options, &body)
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
            @builders ||= []
            @builders << block
          end

          attr_reader :builders

          def active_feature?
            !passive_feature?
          end

          def passive_feature?
            builders.nil?
          end

          def input_pattern(pattern_or_patterns, **options, &converter)
            @input_matcher =
              InputMatcher.new(pattern_or_patterns, options, &converter)
          end

          attr_reader :input_matcher

          def verify(scope, &block)
            @verifiers ||= {}
            (@verifiers[scope] ||= []) << Verifier.new(&block)
          end

          attr_reader :verifiers

          def printable(name, &body)
            @printables ||= {}
            @printables[name] = body
          end

          attr_reader :printables

          def inherited(subclass)
            super
            export_instance_variable(:@properties, subclass, &:dup)
            export_instance_variable(:@ignore_empty_value, subclass)
            export_instance_variable(:@builders, subclass, &:dup)
            export_instance_variable(:@input_matcher, subclass)
            export_instance_variable(:@printables, subclass, &:dup)
            export_verifiers(subclass) if @verifiers
          end

          private

          def export_verifiers(subclass)
            copied_verifiers =
              @verifiers.map { |scope, blocks| [scope, blocks.dup] }.to_h
            subclass.instance_variable_set(:@verifiers, copied_verifiers)
          end
        end

        def_delegator :'self.class', :properties
        def_delegator :'self.class', :active_feature?
        def_delegator :'self.class', :passive_feature?
        def_delegator :'self.class', :ignore_empty_value?

        def build(*args)
          self.class.builders && do_build(args)
        end

        def verify(scope)
          verified?(scope) || do_verify(scope)
        end

        def printables
          helper
            .printables
            &.map { |name, body| [name, printable(name, body)] }
        end

        def printable?
          !helper.printables.nil?
        end

        def inspect
          printable_values =
            printables&.map { |name, value| "#{name}: #{value.inspect}" }
          (printable_values && "#{super}[#{printable_values.join(', ')}]") || super
        end

        private

        def do_build(args)
          @position = args.last.position
          args = [*args[0..-2], args.last.value]
          match_automatically? && match_pattern(args.last)
          Array(self.class.builders)
            .each { |builder| instance_exec(*args, &builder) }
        end

        attr_reader :position

        def match_automatically?
          matcher = self.class.input_matcher
          matcher&.match_automatically?
        end

        def match_pattern(rhs)
          matcher = self.class.input_matcher
          @match_data, @match_index = matcher&.match(rhs)
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
          Array(self.class.verifiers&.at(scope))
            .each { |verifier| verifier.verify(self) }
          (@verified ||= {})[scope] = true
        end

        def printable(name, body)
          body ? instance_exec(&body) : __send__(name)
        end
      end
    end
  end
end

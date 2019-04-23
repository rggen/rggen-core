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

          def verify(scope = :each, &block)
            @verifiers ||= {}
            (@verifiers[scope] ||= []) << block
          end

          def verifiers(scope)
            @verifiers && @verifiers[scope]
          end

          def inherited(subclass)
            super
            export_instance_variable(:@properties, subclass, &:dup)
            export_instance_variable(:@ignore_empty_value, subclass)
            export_instance_variable(:@builders, subclass, &:dup)
            export_instance_variable(:@input_matcher, subclass)
            export_verifiers(subclass) if @verifiers
          end

          private

          def export_verifiers(subclass)
            copied_verifiers =
              @verifiers.map { |scope, blocks| [scope, blocks.dup] }.to_h
            subclass.instance_variable_set(:@verifiers, copied_verifiers)
          end
        end

        delegate_to_class [
          :properties, :active_feature?, :passive_feature?, :ignore_empty_value?
        ]

        def build(*args)
          return unless self.class.builders
          extracted_args = extract_last_arg(args)
          match_pattern(extracted_args.last) if match_automatically?
          execute_blocks(*extracted_args, self.class.builders)
        end

        def verify(scope)
          return if verified?(scope)
          execute_blocks(self.class.verifiers(scope))
          verified(scope)
        end

        private

        def execute_blocks(*args, blocks)
          return unless blocks
          return if blocks.empty?
          blocks.each { |b| instance_exec(*args, &b) }
        end

        def extract_last_arg(args)
          @position = args.last.position
          Array[*args[0..-2], args.last.value].compact
        end

        attr_reader :position

        def match_automatically?
          matcher = self.class.input_matcher
          matcher&.match_automatically?
        end

        def match_pattern(rhs)
          matcher = self.class.input_matcher
          @match_data = matcher&.match(rhs)
        end

        attr_reader :match_data

        def pattern_matched?
          !match_data.nil?
        end

        def verified(scope)
          @verified ||= {}
          @verified[scope] = true
        end

        def verified?(scope)
          @verified && @verified[scope]
        end
      end
    end
  end
end

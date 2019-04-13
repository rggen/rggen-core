# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Feature < Base::Feature
        class << self
          def property(name, **options, &body)
            Property.define(self, name, **options, &body)
            properties.include?(name) || properties << name
          end

          alias_method :field, :property

          def properties
            @properties ||= []
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

          def validate(&block)
            @validators ||= []
            @validators << block
          end

          attr_reader :validators

          def input_pattern(pattern, **options, &converter)
            @match_automatically = options[:match_automatically]
            @input_matcher = InputMatcher.new(pattern, options, &converter)
          end

          attr_reader :input_matcher

          def inherited(subclass)
            super
            export_instance_variable(:@properties, subclass, &:dup)
            export_instance_variable(:@builders, subclass, &:dup)
            export_instance_variable(:@validators, subclass, &:dup)
            export_instance_variable(:@input_matcher, subclass)
            export_instance_variable(:@match_automatically, subclass)
          end

          private

          def define_property(context)
            define_method(context.name) do |*args, &block|
              property_method(context, args, block)
            end
            context.custom_property? && define_custom_property(context)
          end

          def define_custom_property(context)
            method_name = context.custom_property_method_name
            body = context.custom_property_body
            define_private_method(method_name, &body)
          end
        end

        delegate_to_class [
          :properties, :active_feature?, :passive_feature?
        ]

        def build(*args)
          return unless self.class.builders
          extracted_args = extract_last_arg(args)
          match_pattern(extracted_args.last) if match_automatically?
          execute_blocks(*extracted_args, self.class.builders)
        end

        def validate
          return if @validated
          @validated = execute_blocks(self.class.validators)
        end

        private

        def execute_blocks(*args, blocks)
          return unless blocks
          return if blocks.empty?
          blocks.each { |b| instance_exec(*args, &b) }
          true
        end

        def extract_last_arg(args)
          @position = args.last.position
          Array[*args[0..-2], args.last.value].compact
        end

        attr_reader :position

        def match_automatically?
          matcher = self.class.input_matcher
          return false unless matcher
          matcher.options[:match_automatically]
        end

        def match_pattern(rhs)
          matcher = self.class.input_matcher
          @match_data = matcher&.match(rhs)
        end

        attr_reader :match_data

        def pattern_matched?
          !match_data.nil?
        end
      end
    end
  end
end

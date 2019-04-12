# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Feature < Base::Feature
        PropertyContext = Struct.new(:name, :options, :body) do
          def [](key)
            options[key]
          end

          def custom_property?
            return true if options[:body].is_a?(Proc)
            return true if body
            false
          end

          def custom_property_method_name
            "__#{name}__"
          end

          def custom_property_body
            options[:body] || body
          end

          def default_property?
            return false if custom_property?
            return false if options[:forward_to_helper]
            return false if options[:forward_to]
            true
          end

          def property_variable_name
            "@#{name[-1] == '?' ? name[0..-2] : name}"
          end
        end

        class << self
          def property(name, **options, &body)
            define_property(PropertyContext.new(name, options, body))
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

        def property_method(context, args, block)
          context[:need_validation] && validate
          if context.default_property?
            default_property_method(context)
          else
            forwarded_property_method(context, args, block)
          end
        end

        def default_property_method(context)
          variable_name = context.property_variable_name
          if instance_variable_defined?(variable_name)
            instance_variable_get(variable_name)
          else
            context[:default]
          end
        end

        def forwarded_property_method(context, args, block)
          receiver, method_name =
            if context.custom_property?
              [self, context.custom_property_method_name]
            elsif context[:forward_to_helper]
              [self.class, context.name]
            else
              [self, context[:forward_to]]
            end
          receiver.__send__(method_name, *args, &block)
        end
      end
    end
  end
end

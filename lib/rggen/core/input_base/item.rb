module RgGen
  module Core
    module InputBase
      class Item < Base::Item
        define_helpers do
          def field(field_name, options = {}, &body)
            define_method(field_name) do |*args, &block|
              field_method(field_name, options, body, args, block)
            end
            fields.include?(field_name) || fields << field_name
          end

          def fields
            @fields ||= []
          end

          def build(&block)
            @builders ||= []
            @builders << block
          end

          attr_reader :builders

          def active_item?
            !passive_item?
          end

          def passive_item?
            builders.nil?
          end

          def validate(&block)
            @validators ||= []
            @validators << block
          end

          attr_reader :validators

          def input_pattern(pattern, options = {}, &converter)
            @match_automatically = options[:match_automatically]
            @input_matcher = InputMatcher.new(pattern, options, &converter)
          end

          attr_reader :input_matcher

          def match_automatically?
            @match_automatically
          end
        end

        def self.inherited(subclass)
          super
          export_instance_variable(:@fields, subclass, &:dup)
          export_instance_variable(:@builders, subclass, &:dup)
          export_instance_variable(:@validators, subclass, &:dup)
          export_instance_variable(:@input_matcher, subclass)
          export_instance_variable(:@match_automatically, subclass)
        end

        def_class_delegator :fields
        def_class_delegator :active_item?
        def_class_delegator :passive_item?

        def build(*args)
          return unless self.class.builders
          extracted_args = extract_last_arg(args)
          pattern_match(extracted_args.last) if self.class.match_automatically?
          self.class.builders.each { |b| instance_exec(*extracted_args, &b) }
        end

        def validate
          return unless self.class.validators
          return if @validated
          self.class.validators.each { |b| instance_exec(&b) }
          @validated = true
        end

        private

        def extract_last_arg(args)
          @position = args.last.position
          Array[*args.thru(0, -2), args.last.value].compact
        end

        attr_reader :position
        private :position

        def pattern_match(rhs)
          input_matcher = self.class.input_matcher
          @match_data = input_matcher && input_matcher.match(rhs)
        end

        attr_reader :match_data
        private :match_data

        def pattern_matched?
          !match_data.nil?
        end

        def field_method(field_name, options, body, args, block)
          validate if options[:need_validation]
          if body
            instance_exec(*args, &body)
          elsif options[:forward_to_helper]
            self.class.__send__(field_name, *args, &block)
          elsif options.key?(:forward_to)
            __send__(options[:forward_to], *args, &block)
          else
            default_field_method(field_name, options[:default])
          end
        end

        def default_field_method(field_name, default)
          variable_name = (
            (field_name[-1] == '?' && field_name[0..-2]) || field_name
          ).variablize
          if instance_variable_defined?(variable_name)
            instance_variable_get(variable_name)
          else
            default
          end
        end
      end
    end
  end
end

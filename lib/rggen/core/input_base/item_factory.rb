module RgGen
  module Core
    module InputBase
      class ItemFactory < Base::ItemFactory
        class << self
          def convert_value(&block)
            @value_converter = block
          end

          attr_reader :value_converter
        end

        def create(component, *args)
          input_value = preprocess(args.last)
          new_args = [*args.thru(-2), input_value]
          create_item(component, *new_args) do |item|
            build_item(item, input_value)
          end
        end

        def active_item_factory?
          !passive_item_factory?
        end

        def passive_item_factory?
          @target_items.nil? && @target_item.passive_item?
        end

        private

        def preprocess(input_value)
          return input_value if passive_item_factory?
          return input_value if input_value.empty_value?
          return input_value unless self.class.value_converter
          InputValue.new(convert(input_value.value), input_value.position)
        end

        def convert(value)
          instance_exec(value, &self.class.value_converter)
        end

        def build_item(item, input_value)
          return if passive_item_factory?
          return if input_value.empty_value?
          item.build(input_value)
        end
      end
    end
  end
end

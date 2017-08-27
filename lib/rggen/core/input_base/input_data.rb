module RgGen
  module Core
    module InputBase
      class InputData
        def initialize(valid_value_lists)
          @valid_value_lists = valid_value_lists
          @values = Hash.new(NilValue)
          @children = []
          define_setter_methods
          block_given? && yield(self)
        end

        def value(value_name, value, position = nil)
          symbolized_name = value_name.to_sym
          return unless valid_value?(symbolized_name)
          @values[symbolized_name] =
            case value
            when InputValue
              value
            else
              InputValue.new(value, position)
            end
        end

        def []=(value_name, position = nil, value)
          value(value_name, value, position)
        end

        def [](value_name)
          @values[value_name]
        end

        def values(value_list = nil)
          value_list && Hash(value_list).each { |n, v| value(n, v) }
          @values
        end

        attr_reader :children

        def child(value_list = nil, &block)
          InputData.new(@valid_value_lists.from(1)) do |child_data|
            child_data.build_by_block(block)
            child_data.values(value_list)
            @children << child_data
          end
        end

        def load_file(file)
          contents = File.binread(file)
          build_by_block(binding.eval("proc { #{contents} }", file))
        end

        private

        def valid_value?(value_name)
          @valid_value_lists.first.include?(value_name)
        end

        def define_setter_methods
          @valid_value_lists.first.each(&method(:define_setter_method))
        end

        def define_setter_method(value_name)
          define_singleton_method(value_name) do |value, position = nil|
            value_setter(value_name, value, position)
          end
        end

        def value_setter(value_name, value, position)
          position ||= position_from_caller
          value(value_name, value, position)
        end

        def position_from_caller
          locations = caller_locations(3, 2)
          locations[0].path.include?('docile') ? locations[1] : locations[0]
        end

        protected

        def build_by_block(block)
          block && Docile.dsl_eval(self, &block)
        end
      end
    end
  end
end

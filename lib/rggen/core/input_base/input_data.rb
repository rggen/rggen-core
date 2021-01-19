# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class InputData
        def initialize(layer, valid_value_lists)
          @layer = layer
          @valid_value_lists = valid_value_lists
          @values = Hash.new(NAValue)
          @children = []
          define_setter_methods
          block_given? && yield(self)
        end

        attr_reader :layer

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

        def []=(value_name, position_or_value, value = nil)
          value(value_name, value || position_or_value, position_or_value)
        end

        def [](value_name)
          @values[value_name]
        end

        def values(value_list = nil, position = nil)
          value_list && Hash(value_list).each { |n, v| value(n, v, position) }
          @values
        end

        attr_reader :children

        def child(layer, value_list = nil, &block)
          create_child_data(layer) do |child_data|
            child_data.build_by_block(block)
            child_data.values(value_list)
            @children << child_data
          end
        end

        def load_file(file)
          build_by_block(instance_eval(<<~BODY, file, 1))
            -> { #{File.binread(file)} }  # -> { File.binread(file) }
          BODY
        end

        private

        def valid_value?(value_name)
          @valid_value_lists[layer].include?(value_name)
        end

        def define_setter_methods
          @valid_value_lists[layer].each(&method(:define_setter_method))
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
          include_docile_path?(locations[0]) && locations[1] || locations[0]
        end

        def include_docile_path?(caller_location)
          caller_location.path.include?('docile')
        end

        def create_child_data(layer, &block)
          child_data_class.new(layer, @valid_value_lists, &block)
        end

        def child_data_class
          self.class
        end

        protected

        def build_by_block(block)
          block && Docile.dsl_eval(self, &block)
        end
      end
    end
  end
end

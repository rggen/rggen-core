# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class InputData < InputBase::InputData
        def initialize(hierarchy, valid_value_lists)
          @hierarchy = hierarchy
          define_child_creator
          super(valid_value_lists)
        end

        attr_reader :hierarchy

        private

        CHILD_HIERARCHY = {
          register_map: :register_block,
          register_block: :register,
          register: :bit_field
        }.freeze

        def create_child_data(&block)
          InputData.new(
            CHILD_HIERARCHY[hierarchy], @valid_value_lists[1..-1], &block
          )
        end

        def define_child_creator
          return unless CHILD_HIERARCHY.keys.include?(hierarchy)
          singleton_exec(CHILD_HIERARCHY[hierarchy]) do |method_name|
            alias_method method_name, :child
          end
        end
      end
    end
  end
end

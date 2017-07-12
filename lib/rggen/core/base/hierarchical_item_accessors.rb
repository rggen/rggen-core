module RgGen
  module Core
    module Base
      module HierarchicalItemAccessors
        module RegisterMap
          def hierarchy
            :register_map
          end

          def register_map
            @component
          end
        end

        module RegisterBlock
          def hierarchy
            :register_block
          end

          def register_map
            register_block.parent
          end

          def register_block
            @component
          end
        end

        module Register
          def hierarchy
            :register
          end

          def register_map
            register_block.parent
          end

          def register_block
            register.parent
          end

          def register
            @component
          end
        end

        module BitField
          def hierarchy
            :bit_field
          end

          def register_map
            register_block.parent
          end

          def register_block
            register.parent
          end

          def register
            bit_field.parent
          end

          def bit_field
            @component
          end
        end

        private

        ACCESSOR_EXTENSIONS  = [
          RegisterMap, RegisterBlock, Register, BitField
        ].freeze

        def define_hierarchical_item_accessors
          extend ACCESSOR_EXTENSIONS[@component.level]
        end
      end
    end
  end
end

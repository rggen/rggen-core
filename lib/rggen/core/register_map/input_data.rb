# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class BitFieldData < InputBase::InputData
      end

      class RegisterData < InputBase::InputData
        alias_method :bit_field, :child

        def child_data_class
          BitFieldData
        end
      end

      class RegisterBlockData < InputBase::InputData
        alias_method :register, :child

        def child_data_class
          RegisterData
        end
      end

      class RegisterMapData < InputBase::InputData
        alias_method :register_block, :child

        def child_data_class
          RegisterBlockData
        end
      end
    end
  end
end

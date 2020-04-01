# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class InputData < InputBase::InputData
        module Root
          def register_block(value_list = nil, &block)
            child(:register_block, value_list, &block)
          end
        end

        module RegisterBlockRegisterFile
          def register_file(value_list = nil, &block)
            child(:register_file, value_list, &block)
          end

          def register(value_list = nil, &block)
            child(:register, value_list, &block)
          end
        end

        module Register
          def bit_field(value_list = nil, &block)
            child(:bit_field, value_list, &block)
          end
        end

        module BitField
          def self.extended(object)
            object.singleton_exec { undef_method :child }
          end
        end

        LAYER_EXTENSIONS = {
          root: Root, register_block: RegisterBlockRegisterFile,
          register_file: RegisterBlockRegisterFile, register: Register,
          bit_field: BitField
        }.freeze

        def initialize(layer, valid_value_list)
          extend(LAYER_EXTENSIONS[layer])
          super
        end
      end
    end
  end
end

# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class InputData < InputBase::InputData
        module Root
          def register_block(value_list = nil, &)
            child(:register_block, value_list, &)
          end
        end

        module RegisterBlockRegisterFile
          def register_file(value_list = nil, &)
            child(:register_file, value_list, &)
          end

          def register(value_list = nil, &)
            child(:register, value_list, &)
          end
        end

        module Register
          def bit_field(value_list = nil, &)
            child(:bit_field, value_list, &)
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

        def initialize(layer, valid_value_list, configuration)
          extend(LAYER_EXTENSIONS[layer])
          @configuration = configuration
          super(layer, valid_value_list)
        end

        attr_reader :configuration

        private

        def create_child_data(layer, &)
          super(layer, @configuration, &)
        end

        def raise_unknown_field_error(field_name, position)
          message = "unknown register map field is given: #{field_name}"
          error(message, position)
        end
      end
    end
  end
end

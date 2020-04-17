# frozen_string_literal: true

module RgGen
  module Core
    module Base
      module FeatureLayerExtension
        private

        module Common
          def root?
            @component.root?
          end

          def register_block?
            @component.register_block?
          end

          def register_file?
            @component.register_file?
          end

          def register?
            @component.register?
          end

          def bit_field?
            @component.bit_field?
          end
        end

        module Root
          include Common

          def root
            @component
          end
        end

        module RegisterBlock
          include Common

          def root
            register_block.root
          end

          def register_block
            @component
          end

          def register_blocks
            root.register_blocks
          end
        end

        module RegisterFile
          include Common

          def root
            register_file.root
          end

          def register_block
            register_file.register_block
          end

          def block_or_file
            register_file.block_or_file
          end

          def register_file
            @component
          end

          def files_and_registers
            block_or_file.files_and_registers
          end
        end

        module Register
          include Common

          def root
            register.root
          end

          def register_block
            register.register_block
          end

          def register_file
            register.register_file
          end

          def block_or_file
            register.block_or_file
          end

          def register
            @component
          end

          def files_and_registers
            block_or_file.files_and_registers
          end
        end

        module BitField
          include Common

          def root
            bit_field.root
          end

          def register_block
            bit_field.register_block
          end

          def register_file
            bit_field.register_file
          end

          def register
            bit_field.register
          end

          def bit_field
            @component
          end

          def bit_fields
            register.bit_fields
          end
        end

        ACCESSOR_EXTENSIONS = {
          root: Root,
          register_block: RegisterBlock,
          register_file: RegisterFile,
          register: Register,
          bit_field: BitField
        }.freeze

        def define_layer_methods
          extend ACCESSOR_EXTENSIONS[component.layer]
        end
      end
    end
  end
end

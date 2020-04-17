# frozen_string_literal: true

module RgGen
  module Core
    module Base
      module ComponentLayerExtension
        private

        module Common
          def root?
            layer == :root
          end

          def register_block?
            layer == :register_block
          end

          def register_file?
            layer == :register_file
          end

          def register?
            layer == :register
          end

          def bit_field?
            layer == :bit_field
          end
        end

        module Root
          include Common

          def register_blocks
            children
          end

          def register_files
            register_blocks.flat_map(&:register_files)
          end

          def registers
            register_blocks.flat_map(&:registers)
          end

          def bit_fields
            register_blocks.flat_map(&:bit_fields)
          end
        end

        module RegisterBlock
          include Common

          def root
            parent
          end

          def files_and_registers
            children
          end

          def register_files(include_lower_layer = true)
            files_and_registers
              .select(&:register_file?)
              .flat_map { |rf| [rf, *(include_lower_layer ? rf : nil)&.register_files] }
          end

          def registers(include_lower_layer = true)
            files_and_registers.flat_map do |file_or_register|
              if file_or_register.register?
                file_or_register
              else
                [*(include_lower_layer ? file_or_register : nil)&.registers]
              end
            end
          end

          def bit_fields
            registers.flat_map(&:bit_fields)
          end
        end

        module RegisterFile
          include Common

          def root
            register_block.root
          end

          def block_or_file
            parent
          end

          def register_block
            parent.register_block? && parent || parent.register_block
          end

          def files_and_registers
            children
          end

          def register_files(include_lower_layer = true)
            files_and_registers
              .select(&:register_file?)
              .flat_map { |rf| [rf, *(include_lower_layer ? rf : nil)&.register_files] }
          end

          def registers(include_lower_layer = true)
            files_and_registers.flat_map do |file_or_register|
              if file_or_register.register?
                file_or_register
              else
                [*(include_lower_layer ? file_or_register : nil)&.registers]
              end
            end
          end

          def bit_fields
            registers.flat_map(&:bit_fields)
          end
        end

        module Register
          include Common

          def root
            parent.root
          end

          def register_block
            parent.register_block? && parent || parent.register_block
          end

          def register_file
            parent.register_file? && parent || nil
          end

          def block_or_file
            parent
          end

          def bit_fields
            children
          end
        end

        module BitField
          include Common

          def root
            parent.root
          end

          def register_block
            parent.register_block
          end

          def register_file
            parent.register_file
          end

          def register
            parent
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
          extend ACCESSOR_EXTENSIONS[layer]
        end
      end
    end
  end
end

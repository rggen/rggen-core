# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      module HashLoader
        def format(read_data, file)
          format_data(:root, root, read_data, file)
        rescue TypeError => e
          raise Core::LoadError.new(e.message, file)
        end

        private

        LAYER_MAP = {
          root: { register_blocks: :register_block },
          register_block: { register_files: :register_file, registers: :register },
          register_file: { register_files: :register_file, registers: :register },
          register: { bit_fields: :bit_field }
        }.freeze

        def format_data(layer, input_data, read_data, file)
          read_data = Hash(read_data)
          input_data.values(read_data, file)
          format_next_layer_data(layer, input_data, read_data, file)
        end

        def format_next_layer_data(layer, input_data, read_data, file)
          LAYER_MAP[layer]&.each do |key, next_layer|
            Array(read_data[key]).each do |data|
              format_data(
                next_layer, input_data.child(next_layer), data, file
              )
            end
          end
        end
      end
    end
  end
end

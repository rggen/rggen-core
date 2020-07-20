# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      module HashLoader
        private

        SUB_LAYER_KEYS = {
          root: [:register_block, :register_blocks],
          register_block: [:register_file, :register_files, :register, :registers],
          register_file: [:register_file, :register_files, :register, :registers],
          register: [:bit_field, :bit_fields]
        }.freeze

        SUB_LAYER_KEY_MAP = {
          root: { register_blocks: :register_block },
          register_block: { register_files: :register_file, registers: :register },
          register_file: { register_files: :register_file, registers: :register },
          register: { bit_fields: :bit_field }
        }.freeze

        def format_layer_data(read_data, layer, file)
          if read_data.is_a?(Array)
            format_array_layer_data(read_data, layer, file)
          else
            fomrat_hash_layer_data(read_data, layer, file)
          end
        end

        def format_array_layer_data(read_data, layer, file)
          read_data.each_with_object({}) do |data, layer_data|
            layer_data.merge!(fomrat_hash_layer_data(data, layer, file))
          end
        end

        def fomrat_hash_layer_data(read_data, layer, file)
          convert_to_hash(read_data, file)
            .reject { |key, _| SUB_LAYER_KEYS[layer]&.include?(key) }
        end

        def format_sub_layer_data(read_data, layer, file)
          if read_data.is_a?(Array)
            format_array_sub_layer_data(read_data, layer, file)
          else
            format_hash_sub_layer_data(read_data, layer, file)
          end
        end

        def format_array_sub_layer_data(read_data, layer, file)
          read_data.each_with_object({}) do |data, sub_layer_data|
            format_hash_sub_layer_data(data, layer, file, sub_layer_data)
          end
        end

        def format_hash_sub_layer_data(read_data, layer, file, sub_layer_data = {})
          convert_to_hash(read_data, file)
            .select { |key, _| SUB_LAYER_KEYS[layer]&.include?(key) }
            .each do |key, value|
              merge_sub_layer_data(sub_layer_data, layer, key, value)
            end
          sub_layer_data
        end

        def merge_sub_layer_data(sub_layer_data, layer, key, value)
          if SUB_LAYER_KEY_MAP[layer].key?(key)
            (sub_layer_data[SUB_LAYER_KEY_MAP[layer][key]] ||= []).concat(value)
          else
            (sub_layer_data[key] ||= []) << value
          end
        end

        def convert_to_hash(read_data, file)
          Hash(read_data)
        rescue TypeError => e
          raise Core::LoadError.new(e.message, file)
        end
      end
    end
  end
end

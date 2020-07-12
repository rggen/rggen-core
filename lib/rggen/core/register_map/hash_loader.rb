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

        def format_data(layer, input_data, read_data, file)
          property_data, sub_layer_data =
            if read_data.is_a?(Array)
              split_array_data(layer, read_data)
            else
              split_hash_data(layer, read_data)
            end
          input_data.values(property_data, file)
          format_sub_layer_data(input_data, sub_layer_data, file)
        end

        def split_array_data(layer, read_data)
          property_data = {}
          sub_layer_data = {}
          read_data
            .each { |data| split_hash_data(layer, data, property_data, sub_layer_data) }
          [property_data, sub_layer_data]
        end

        def split_hash_data(layer, read_data, property_data = {}, sub_layer_data = {})
          read_data = Hash(read_data)
          collect_property_data(layer, read_data, property_data)
          collect_sub_layer_data(layer, read_data, sub_layer_data)
          [property_data, sub_layer_data]
        end

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

        def collect_property_data(layer, read_data, property_data)
          property_data
            .merge!(read_data.reject { |key, _| SUB_LAYER_KEYS[layer]&.include?(key) })
        end

        def collect_sub_layer_data(layer, read_data, sub_layer_data)
          read_data
            .select { |key, _| SUB_LAYER_KEYS[layer]&.include?(key) }
            .each do |key, value|
              merge_sub_layer_data(sub_layer_data, layer, key, value)
            end
        end

        def merge_sub_layer_data(sub_layer_data, layer, key, value)
          if SUB_LAYER_KEY_MAP[layer].key?(key)
            (sub_layer_data[SUB_LAYER_KEY_MAP[layer][key]] ||= []).concat(value)
          else
            (sub_layer_data[key] ||= []) << value
          end
        end

        def format_sub_layer_data(input_data, sub_layer_data, file)
          sub_layer_data
            .flat_map { |sub_layer, values| [sub_layer].product(values) }
            .each do |(sub_layer, value)|
              format_data(sub_layer, input_data.child(sub_layer), value, file)
            end
        end
      end
    end
  end
end

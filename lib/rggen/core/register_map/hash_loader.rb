module RgGen
  module Core
    module RegisterMap
      module HashLoader
        def format(read_data, file)
          format_data(:register_map, register_map, read_data, file)
        rescue TypeError => e
          raise Core::LoadError.new(e.message, file)
        end

        private

        CHILD_HIERARCHY = {
          register_map: :register_block,
          register_block: :register,
          register: :bit_field
        }.freeze

        CHILD_HIERARCHY_KEY = {
          register_map: :register_blocks,
          register_block: :registers,
          register: :bit_fields
        }.freeze

        def format_data(hierarchy, input_data, read_data, file)
          read_data = Hash(read_data).symbolize_keys
          input_data.values(read_data, file)
          get_child_read_data(hierarchy, read_data).each do |child_read_data|
            format_data(
              CHILD_HIERARCHY[hierarchy],
              input_data.child,
              child_read_data,
              file
            )
          end
        end

        def get_child_read_data(hierarchy, read_data)
          key = CHILD_HIERARCHY_KEY[hierarchy]
          Array(key && read_data[key])
        end
      end
    end
  end
end

module RgGen
  module Core
    module InputBase
      class Loader
        class << self
          def supported_types(types)
            @supported_types = types.map(&:to_sym)
          end

          def support?(file)
            file_ext = File.ext(file).to_sym
            @supported_types.any? { |type| type.casecmp(file_ext).zero? }
          end

          def load_file(file, input_data, valid_value_list)
            new(input_data, valid_value_list).load_file(file)
          end
        end

        def initialize(input_data, valid_value_lists)
          @input_data = input_data
          @valid_value_lists = valid_value_lists
        end

        def load_file(file)
          File.readable?(file) || (raise Core::LoadError.new(file))
          form(read_file(file))
        end

        attr_reader :input_data
        private :input_data

        attr_reader :valid_value_lists
        private :valid_value_lists

        private

        def form(_read_data)
        end
      end
    end
  end
end

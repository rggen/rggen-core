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

        def initialize(input_data, valid_value_list)
          @input_data = input_data
          @valid_value_list = valid_value_list
        end

        def load_file(file)
          read_data =
            begin
              read_file(file)
            rescue
              raise Core::LoadError.new(file)
            end
          form(read_data)
        end

        attr_reader :input_data
        private :input_data

        attr_reader :valid_value_list
        private :valid_value_list

        private

        def form(_read_data)
        end
      end
    end
  end
end

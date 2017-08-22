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

          def load_file(file, input_data)
            new(input_data).load_file(file)
          end
        end

        def initialize(input_data)
          @input_data = input_data
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

        def form(_read_data)
        end
      end
    end
  end
end

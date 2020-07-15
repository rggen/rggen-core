# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Loader
        def self.support_types(types = nil)
          types && (@support_types ||= []).concat(types.map(&:to_sym))
          @support_types
        end

        def support?(file)
          ext = File.ext(file).to_sym
          types = self.class.support_types
          types&.any? { |type| type.casecmp?(ext) } || false
        end

        def load_file(file, input_data, valid_value_lists)
          File.readable?(file) ||
            (raise Core::LoadError.new('cannot load such file', file))
          @input_data = input_data
          @valid_value_lists = valid_value_lists
          format(read_file(file), file)
        end

        private

        def format(_read_data, _file)
        end

        attr_reader :input_data
        attr_reader :valid_value_lists
      end
    end
  end
end

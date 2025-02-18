# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Loader
        include RaiseError

        def self.support_types(types = nil)
          types && (@support_types ||= []).concat(types.map(&:to_sym))
          @support_types
        end

        def self.require_no_input_file
          @require_input_file = false
        end

        def initialize(extractors, ignore_values)
          @extractors = extractors
          @ignore_values = ignore_values
        end

        def support?(file)
          ext = File.ext(file).to_sym
          types = self.class.support_types
          types&.any? { |type| type.casecmp?(ext) } || false
        end

        def require_input_file?
          loader = self.class
          !loader.instance_variable_defined?(:@require_input_file) ||
            loader.instance_variable_get(:@require_input_file)
        end

        def load_data(input_data, valid_value_lists, file = nil)
          if require_input_file?
            load_file(input_data, valid_value_lists, file)
          else
            load_builtin_data(input_data)
          end
        end

        def load_file(input_data, valid_value_lists, file)
          File.readable?(file) ||
            (raise Core::LoadError.new('cannot load such file', file))
          @input_data = input_data
          @valid_value_lists = valid_value_lists
          format_data(read_file(file), input_data, input_data.layer, file)
        end

        private

        attr_reader :input_data

        def format_data(read_data, input_data, layer, file)
          layer_data =
            format_layer_data(read_data, layer, file) ||
            format_layer_data_by_extractors(read_data, layer)
          layer_data &&
            input_data.values(filter_layer_data(layer_data, layer), file)
          format_sub_layer(read_data, input_data, layer, file)
        end

        def format_sub_layer(read_data, input_data, layer, file)
          format_sub_layer_data(read_data, layer, file)&.each do |(sub_layer, data)|
            format_data(data, input_data.child(sub_layer), sub_layer, file)
          end
        end

        def format_layer_data(_read_data, _layer, _file)
        end

        def format_layer_data_by_extractors(read_data, layer)
          layer_data =
            valid_values(layer)
              .map { |value_name| extract_value(read_data, layer, value_name) }
              .compact.to_h
          layer_data.empty? ? nil : layer_data
        end

        def extract_value(read_data, layer, value_name)
          value =
            @extractors
              .select { |extractor| extractor.target_value?(layer, value_name) }
              .map { |extractor| extractor.extract(read_data) }
              .compact.last
          value && [value_name, value]
        end

        def filter_layer_data(layer_data, layer)
          if @ignore_values.key?(layer)
            layer_data.except(*@ignore_values[layer])
          else
            layer_data
          end
        end

        def format_sub_layer_data(_read_data, _layer, _file)
        end

        def valid_values(layer)
          list = @valid_value_lists[layer]
          ignore_values = @ignore_values[layer]
          ignore_values && (list - ignore_values) || list
        end
      end
    end
  end
end

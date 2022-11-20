# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      module YAMLLoader
        Position = Struct.new(:file, :line, :column) do
          def to_s
            "file #{file} line #{line} column #{column}"
          end
        end

        module PsychExtension
          refine ::Psych::Nodes::Node do
            attr_accessor :filename

            attr_writer :mapping_key

            def mapping_key?
              @mapping_key || false
            end
          end
        end

        using PsychExtension

        class TreeBuilder < ::Psych::TreeBuilder
          def initialize(filename)
            super()
            @filename = filename
          end

          def set_start_location(node)
            super
            node.filename = @filename
          end

          def scalar(value, anchor, tag, plain, quated, style)
            node = super
            node.mapping_key = mapping_key?
            node
          end

          private

          def mapping_key?
            @last.mapping? && @last.children.size.odd?
          end
        end

        class Visitor < ::Psych::Visitors::ToRuby
          if ::Psych::VERSION >= '3.2.0'
            def initialize(scalar_scanner, class_loader)
              super(scalar_scanner, class_loader, symbolize_names: true)
            end
          end

          def accept(node)
            object = super
            if override_object?(node)
              file = node.filename
              line = node.start_line + 1
              column = node.start_column + 1
              InputValue.new(object, Position.new(file, line, column))
            else
              object
            end
          end

          private

          def override_object?(node)
            node.mapping? || node.sequence? || (node.scalar? && !node.mapping_key?)
          end
        end

        private

        def load_yaml(file)
          parse_yaml(File.binread(file), file)
            .then { |result| to_ruby(result) }
            .then { |result| symbolize_names(result) }
        end

        def parse_yaml(yaml, file)
          parser = ::Psych::Parser.new(TreeBuilder.new(file))
          parser.parse(yaml, file)
          parser.handler.root.children.first
        end

        def to_ruby(result)
          cl = ::Psych::ClassLoader::Restricted.new(['Symbol'], [])
          ss = ::Psych::ScalarScanner.new(cl)
          Visitor.new(ss, cl).accept(result)
        end

        def symbolize_names(result)
          return result if ::Psych::VERSION >= '3.2.0'

          if result.match_class?(Hash)
            result
              .transform_keys!(&:to_sym)
              .transform_values!(&method(:symbolize_names))
          elsif result.match_class?(Array)
            result.map! { |value| symbolize_names(value) }
          end

          result
        end
      end
    end
  end
end

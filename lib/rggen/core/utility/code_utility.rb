# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module CodeUtility
        def create_blank_code
          code_block
        end

        module_function

        def newline
          "\n"
        end

        def nl
          newline
        end

        def comma
          ','
        end

        def colon
          ':'
        end

        def semicolon
          ';'
        end

        def space(size = 1)
          ' ' * size
        end

        def string(expression)
          "\"#{expression}\""
        end

        def array_name(name, size)
          [name, *size&.map { |s| "[#{s}]" }].join
        end

        def code_block(indent = 0, &body)
          CodeBlock.new(indent, &body)
        end

        def indent(code, indent_size)
          code << nl unless code.last_line_empty?
          code.indent += indent_size
          block_given? && yield(code)
          code << nl unless code.last_line_empty?
          code.indent -= indent_size
        end

        def wrap(code, head, tail)
          code << head
          block_given? && yield(code)
          code << tail
        end

        def loop_index(level = 1)
          return '' unless level.positive?
          (1...level).inject(+'i') { |index, _| index.next! }
        end
      end
    end
  end
end

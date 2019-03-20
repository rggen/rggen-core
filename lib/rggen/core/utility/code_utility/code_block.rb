# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module CodeUtility
        class CodeBlock
          def initialize(indent = 0)
            @indent = indent
            @lines = []
            add_line
            block_given? && yield(self)
          end

          attr_reader :indent

          def <<(rhs)
            case rhs
            when String
              add_string(rhs)
            when CodeBlock
              merge_code_block(rhs)
            else
              add_word(rhs)
            end
            self
          end

          def indent=(indent)
            @indent = indent
            last_line.indent = indent
          end

          def last_line_empty?
            last_line.empty?
          end

          def to_s
            @lines.map(&:to_s).each(&:rstrip!).join(newline)
          end

          def eval_block(&block)
            return unless block_given?
            block.arity.zero? ? self << yield : yield(self)
          end

          private

          def add_line
            line = Line.new(@indent)
            @lines << line
          end

          def add_string(rhs)
            lines =
              if rhs.include?(newline)
                (rhs.end_with?(newline) ? rhs + newline : rhs).lines
              else
                [rhs]
              end
            lines.each_with_index do |line, i|
              i.positive? && add_line
              add_word(line.chomp)
            end
          end

          def merge_code_block(rhs)
            rhs.lines.each_with_index do |line, i|
              i.positive? && add_line
              line.empty? || (last_line.indent += line.indent)
              last_line.concat(line)
            end
          end

          def last_line
            @lines.last
          end

          def add_word(word)
            last_line << word
          end

          def newline
            "\n"
          end

          protected

          attr_reader :lines
        end
      end
    end
  end
end

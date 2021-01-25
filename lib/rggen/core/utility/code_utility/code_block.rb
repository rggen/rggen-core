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
            when String then push_string(rhs)
            when CodeBlock then push_code_block(rhs)
            when Array then rhs.inject(self, :<<)
            when code? then self << rhs.to_code
            else push_word(rhs)
            end
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

          def push_string(rhs)
            rhs += newline if rhs.end_with?(newline)
            rhs.each_line.with_index do |line, i|
              i.positive? && add_line
              push_word(line.chomp)
            end
            self
          end

          def push_code_block(rhs)
            rhs.lines.each_with_index do |line, i|
              i.positive? && add_line
              line.empty? || (last_line.indent += line.indent)
              last_line.concat(line)
            end
            self
          end

          def last_line
            @lines.last
          end

          def push_word(word)
            last_line << word
            self
          end

          def code?
            ->(rhs) { rhs.respond_to?(:to_code) }
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

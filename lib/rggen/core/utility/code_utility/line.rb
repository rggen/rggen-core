# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module CodeUtility
        class Line
          def initialize(indent = 0)
            @indent = indent
            @words = []
          end

          attr_reader :indent

          def indent=(indent)
            empty? && (@indent = indent)
          end

          def <<(word)
            @words << word
            self
          end

          def concat(line)
            @words.concat(line.words)
          end

          def empty?
            @words.all?(&method(:empty_word?))
          end

          def to_s
            [' ' * (@indent || 0), *@words].join
          end

          private

          def empty_word?(word)
            return true if word.nil?
            return false unless word.respond_to?(:empty?)
            word.empty?
          end

          protected

          attr_reader :words
        end
      end
    end
  end
end

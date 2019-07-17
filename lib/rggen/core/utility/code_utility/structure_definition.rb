# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module CodeUtility
        class StructureDefinition
          include CodeUtility

          def initialize
            block_given? && yield(self)
          end

          def body(&block)
            return unless block_given?
            (@bodies ||= []) << [block, 2]
          end

          def to_code
            CodeBlock.new do |code|
              code_blocks.each do |block, indent_size|
                indent(code, indent_size) { code.eval_block(&block) }
              end
            end
          end

          private

          def header_code
          end

          def pre_body_code
          end

          def post_body_code
          end

          def footer_code
          end

          def code_blocks
            blocks = []
            blocks << [method(:header_code), 0]
            blocks << [method(:pre_body_code), 2]
            blocks.concat(Array(@bodies))
            blocks << [method(:post_body_code), 2]
            blocks << [method(:footer_code), 0]
            blocks
          end
        end
      end
    end
  end
end

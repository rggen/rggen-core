# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class CodeGenerator
        def register(kind, &block)
          block_given? && (code_blocks[kind] << block)
        end

        def generate(context, code, kind)
          code_blocks[kind].each do |block|
            execute_code_block(context, code, &block)
          end
        end

        def copy
          generator = CodeGenerator.new
          generator.copy_code_blocks(@code_blocks) if @code_blocks
          generator
        end

        private

        def code_blocks
          @code_blocks ||= Hash.new { |blocks, kind| blocks[kind] = [] }
        end

        def execute_code_block(context, code, &block)
          if block.arity.zero?
            code << context.instance_exec(&block)
          else
            context.instance_exec(code, &block)
          end
        end

        protected

        def copy_code_blocks(original_blocks)
          original_blocks.each { |kind, blocks| code_blocks[kind] = blocks.dup }
        end
      end
    end
  end
end
